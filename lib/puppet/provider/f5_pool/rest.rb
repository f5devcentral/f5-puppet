require 'puppet/provider/f5'
require 'json'

Puppet::Type.type(:f5_pool).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    nodes = Puppet::Provider::F5.call('/mgmt/tm/ltm/pool')
    return [] if nodes.nil?

    nodes.each do |node|
      # Map 0 nodes to disabled.
      node['minActiveMembers'] = 'disabled' if node['minActiveMembers'] == 0

      # We have to munge availability out of the monitor information.
      if node['monitor']
        availability = find_availability(node['monitor'])
        monitor = find_objects(node['monitor'])
      end

      # Instead of true/false the F5 returns yes/no
      node.each { |_,v| v.gsub!(/^yes$/, 'true') if v.is_a?(String) }
      node.each { |_,v| v.gsub!(/^no$/, 'false') if v.is_a?(String) }

      # Select reject in the GUI, get reset from the REST api.  Who knows!
      node['serviceDownAction'] = 'reject' if node['serviceDownAction'] == 'reset'

      # We only accept true/false for some parameters.
      node['queueOnConnectionLimit'] = :true  if node['queueOnConnectionLimit'] == 'enabled'
      node['queueOnConnectionLimit'] = :false if node['queueOnConnectionLimit'] == 'disabled'
      node['ignorePersistedWeight'] = :true  if node['ignorePersistedWeight'] == 'enabled'
      node['ignorePersistedWeight'] = :false if node['ignorePersistedWeight'] == 'disabled'

      # We force everything to a string because we get Integers from the F5 and
      # strings back from the type, meaning it churns properties for no reason.
      create = {
        ensure:                    :present,
        name:                      node['fullPath'].to_s,
        description:               node['description'].to_s,
        allow_snat:                node['allowSnat'].to_s,
        allow_nat:                 node['allowNat'].to_s,
        service_down:              node['serviceDownAction'].to_s,
        slow_ramp_time:            node['slowRampTime'].to_s,
        ip_tos_to_client:          node['ipTosToClient'].to_s,
        ip_tos_to_server:          node['ipTosToServer'].to_s,
        link_qos_to_client:        node['linkQosToClient'].to_s,
        link_qos_to_server:        node['linkQosToServer'].to_s,
        reselect_tries:            node['reselectTries'].to_s,
        request_queuing:           node['queueOnConnectionLimit'].to_s,
        request_queue_depth:       node['queueDepthLimit'].to_s,
        request_queue_timeout:     node['queueTimeLimit'].to_s,
        ip_encapsulation:          node['profiles'], # An array!
        load_balancing_method:     node['loadBalancingMode'].to_s,
        priority_group_activation: node['minActiveMembers'].to_s,
        ignore_persisted_weight:   node['ignorePersistedWeight'].to_s,
      }
      # Only create this entry if availability was found.
      create[:availability] = availability if availability
      create[:monitor] = monitor if monitor

      instances << new(create)
    end

    instances
  end

  def self.prefetch(resources)
    nodes = instances
    resources.keys.each do |name|
      if provider = nodes.find { |node| node.name == name }
        resources[name].provider = provider
      end
    end
  end

  def basename
    File.basename(resource[:name])
  end

  def partition
    File.dirname(resource[:name])
  end

  def message(object)
    # Here lies some evil magic.  We want to replace all _'s with -'s in the
    # key names of the hash we create from the object we've passed into message.
    #
    # We do this by passing in an object along with .each, giving us an empty
    # hash to then build up with the fixed names.
    hash = object.to_hash.each_with_object({}) do |(k ,v), obj|
      key = k.to_s.gsub(/_/, '-').to_sym
      obj[key] = v
    end

    # Create the message by stripping :present.
    message             = hash.reject { |k, _| [:ensure, :loglevel, :provider].include?(k) }
    message[:name]      = basename
    message[:partition] = partition

    # Do a bunch of renaming back to what the API expects.  This is awful.
    # We have to wrap each of the tests that use .to_sym in a check if they
    # even exist, otherwise we try to nil.to_sym.
    message[:'priority-group-activation'] = 0 if hash[:'priority-group-activation'] == 'disabled'

    if hash[:'allow-nat']
      message[:'allow-nat']  = 'yes' if hash[:'allow-nat'].to_sym == :true
      message[:'allow-nat']  = 'no'  if hash[:'allow-nat'].to_sym == :false
    end

    if hash[:'allow-snat']
      message[:'allow-snat'] = 'yes' if hash[:'allow-snat'].to_sym == :true
      message[:'allow-snat'] = 'no'  if hash[:'allow-snat'].to_sym == :false
    end

    if hash[:'ignore-persisted-weight']
      message[:'ignore-persisted-weight'] = 'enabled' if hash[:'ignore-persisted-weight'].to_sym == :true
      message[:'ignore-persisted-weight'] = 'disabled' if hash[:'ignore-persisted-weight'].to_sym == :false
    end

    # Set this in the hash so map picks it up.
    if hash[:'service-down']
      hash[:'service-down'] = 'reset' if hash[:'service-down'].to_sym == :reject
    end
    if hash[:'request-queuing']
      hash[:'request-queuing'] = 'disabled' if hash[:'request-queuing'].to_sym == :false
      hash[:'request-queuing'] = 'enabled' if hash[:'request-queuing'].to_sym == :true
    end

    map = {
      :'service-down'              => :'service-down-action',
      :'request-queuing'           => :'queue-on-connection-limit',
      :'request-queue-depth'       => :'queue-depth-limit',
      :'request-queue-timeout'     => :'queue-time-limit',
      :'ip-encapsulation'          => :'profiles',
      :'load-balancing-method'     => :'load-balancing-mode',
      :'priority-group-activation' => :'min-active-members',
    }

    # We need to rename some properties back to the API.
    map.each do |k, v|
      next unless hash[k]
      value = hash[k]
      message.delete(k)
      message[v] = value
    end

    # Apply transformations
    message.each do |k, v|
      message[k] = Integer(v) if Puppet::Provider::F5.integer?(v)
    end
    # Despite only allowing a single entry, profiles must be an array.
    message[:profiles] = Array(message[:profiles])

    # If monitor is an array then we need to rebuild the message.
    if message[:monitor].is_a?(Array)
      message.reject! { |k, _| [:monitor, :availability].include?(k) }
      message[:monitor] = "min #{hash[:availability]} of #{hash[:monitor].join(' ')}"
    end

    message.to_json
  end

  def flush
    if @property_hash != {}
      result = Puppet::Provider::F5.put("/mgmt/tm/ltm/pool/#{basename}", message(@property_hash))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    Puppet::Provider::F5.post("/mgmt/tm/ltm/pool", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear
  end

  def destroy
    Puppet::Provider::F5.delete("/mgmt/tm/ltm/pool/#{basename}")
    @property_hash.clear
  end

  mk_resource_methods

end
