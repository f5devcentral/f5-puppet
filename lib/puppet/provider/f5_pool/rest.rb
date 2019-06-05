require File.join(File.dirname(__FILE__), '../f5')
Puppet::Type.type(:f5_node)
require 'json'

Puppet::Type.type(:f5_pool).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    pools = Puppet::Provider::F5.call_items('/mgmt/tm/ltm/pool')
    return [] if pools.nil?

    pools.each do |pool|
      # We get back an array from profiles, but we need a string.  We take
      # the first element of the array as we SHOULD only have one entry here.
      pool['profiles'] = pool['profiles'].first if pool['profiles']

      # Map 0 pools to disabled.
      pool['minActiveMembers'] = 'disabled' if pool['minActiveMembers'] == 0

      # Instead of true/false the F5 returns yes/no
      pool.each { |_,v| v.gsub!(/^yes$/, 'true') if v.is_a?(String) }
      pool.each { |_,v| v.gsub!(/^no$/, 'false') if v.is_a?(String) }

      # Select reject in the GUI, get reset from the REST api.  Who knows!
      pool['serviceDownAction'] = 'reject' if pool['serviceDownAction'] == 'reset'

      # We only accept true/false for some parameters.
      pool['queueOnConnectionLimit'] = :true  if pool['queueOnConnectionLimit'] == 'enabled'
      pool['queueOnConnectionLimit'] = :false if pool['queueOnConnectionLimit'] == 'disabled'
      pool['ignorePersistedWeight'] = :true  if pool['ignorePersistedWeight'] == 'enabled'
      pool['ignorePersistedWeight'] = :false if pool['ignorePersistedWeight'] == 'disabled'

      # Handle members.  This gets messy.
      members = []
      if pool['membersReference']['items']
        pool['membersReference']['items'].each do |member|
          name, port = member['fullPath'].split(':')
          members << {
            'name' => name,
            'port' => port.to_s,
          }
        end
      end
      members << 'none' if members.empty?

      # We force everything to a string because we get Integers from the F5 and
      # strings back from the type, meaning it churns properties for no reason.
      create = {
        ensure:                    :present,
        name:                      pool['fullPath'],
        allow_nat:                 pool['allowNat'],
        allow_snat:                pool['allowSnat'],
        availability_requirement:  find_availability(pool['monitor']),
        description:               pool['description'],
        health_monitors:           find_monitors(pool['monitor']),
        ignore_persisted_weight:   pool['ignorePersistedWeight'],
        ip_encapsulation:          pool['profiles'],
        ip_tos_to_client:          pool['ipTosToClient'],
        ip_tos_to_server:          pool['ipTosToServer'],
        link_qos_to_client:        pool['linkQosToClient'],
        link_qos_to_server:        pool['linkQosToServer'],
        load_balancing_method:     pool['loadBalancingMode'],
        priority_group_activation: pool['minActiveMembers'],
        request_queue_depth:       pool['queueDepthLimit'].to_s,
        request_queue_timeout:     pool['queueTimeLimit'].to_s,
        request_queuing:           pool['queueOnConnectionLimit'],
        reselect_tries:            pool['reselectTries'].to_s,
        service_down:              pool['serviceDownAction'] || "none",
        slow_ramp_time:            pool['slowRampTime'].to_s,
      }
      # Only create this entry if members were found.
      create[:members] = members if members

      instances << new(create)
    end

    instances
  end

  # state: unchecked, session: user-enabled  -> GUI enabled.
  # state: unchecked, session: user-disabled -> GUI disabled.
  # state: user-down, session: user-disabled -> GUI forced offline.
  def self.enable(member)
    case member['state']
    when 'down'
    # Temporary hack while I figure out how to handle monitor down.
      return 'enabled' if member['session'] == 'monitor-enabled'
    when 'unchecked', 'up'
      case member['session']
      when 'user-enabled', 'monitor-enabled'
        return 'enabled'
      else
        return 'disabled'
      end
    when 'user-down'
      return 'forced_offline' if member['session'] = 'user-disabled'
    else
      fail ArgumentError, 'Unknown state detected for enable.'
    end
  end

  def self.prefetch(resources)
    pools = instances
    resources.keys.each do |name|
      if provider = pools.find { |pool| pool.name == name }
        resources[name].provider = provider
      end
    end
  end

  def convert_underscores(hash)
    # Here lies some evil magic.  We want to replace all _'s with -'s in the
    # key names of the hash we create from the object we've passed into message.
    #
    # We do this by passing in an object along with .each, giving us an empty
    # hash to then build up with the fixed names.
    hash.each_with_object({}) do |(k ,v), obj|
      key = k.to_s.gsub(/_/, '-').to_sym
      obj[key] = v
    end
  end

  def message(object)
    # Allows us to pass in resources and get all the attributes out
    # in the form of a hash.
    message = object.to_hash

    map = {
      :'service-down'              => :'service-down-action',
      :'request-queuing'           => :'queue-on-connection-limit',
      :'request-queue-depth'       => :'queue-depth-limit',
      :'request-queue-timeout'     => :'queue-time-limit',
      :'ip-encapsulation'          => :'profiles',
      :'load-balancing-method'     => :'load-balancing-mode',
      :'priority-group-activation' => :'min-active-members',
      :'availability-requirement'  => :availability,
      :'health-monitors'           => :monitor,
    }

    # We need to rename some properties back to the API.
    message = strip_nil_values(message)
    message = convert_underscores(message)
    message = rename_keys(map, message)
    message = create_message(basename, partition, message)
    message = string_to_integer(message)
    message = monitor_conversion(message)

    if message[:members]
      if message[:members] == ['none']
        message[:members] = []
      else
        # Members is a whole world of pain.
        members = []
        nodes = Puppet::Type::F5_node.instances
        message[:members].each do |member|
          node = nodes.find do |node|
            node.name == member['name']
          end
          fail ArgumentError, "Could not find existing f5_node with the name '#{member['node']}'" if node.nil?
          node = node.provider
          member[:name] = "#{member['name']}:#{member['port']}"
          member.delete('port')

          unless node.address == 'any6'
            member[:address] = node.address
          end
          converted = convert_underscores(member)
          members << converted
        end
        message[:members] = members
      end
    end

    # Do a bunch of renaming back to what the API expects.  This is awful.
    # We have to wrap each of the tests that use .to_sym in a check if they
    # even exist, otherwise we try to nil.to_sym.
    message[:'min-active-members'] = 0 if message[:'min-active-members'] == 'disabled'

    if message[:'allow-nat']
      message[:'allow-nat']  = 'yes' if message[:'allow-nat'].to_sym == :true
      message[:'allow-nat']  = 'no'  if message[:'allow-nat'].to_sym == :false
    end

    if message[:'allow-snat']
      message[:'allow-snat'] = 'yes' if message[:'allow-snat'].to_sym == :true
      message[:'allow-snat'] = 'no'  if message[:'allow-snat'].to_sym == :false
    end

    if message[:'ignore-persisted-weight']
      message[:'ignore-persisted-weight'] = 'enabled' if message[:'ignore-persisted-weight'].to_sym == :true
      message[:'ignore-persisted-weight'] = 'disabled' if message[:'ignore-persisted-weight'].to_sym == :false
    end

    # Set this in the hash so map picks it up.
    if message[:'service-down-action']
      message[:'service-down-action'] = 'reset' if message[:'service-down-action'].to_sym == :reject
    end
    if message[:'queue-on-connection-limit']
      message[:'queue-on-connection-limit'] = 'disabled' if message[:'queue-on-connection-limit'].to_sym == :false
      message[:'queue-on-connection-limit'] = 'enabled' if message[:'queue-on-connection-limit'].to_sym == :true
    end

    # Despite only allowing a single entry, profiles must be an array.
    message[:profiles] = Array(message[:profiles])

    message.to_json
  end

  def flush
    if @property_hash != {}
      result = Puppet::Provider::F5.put("/mgmt/tm/ltm/pool/#{api_name}", message(@property_hash))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    result = Puppet::Provider::F5.post("/mgmt/tm/ltm/pool", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    result = Puppet::Provider::F5.delete("/mgmt/tm/ltm/pool/#{api_name}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
