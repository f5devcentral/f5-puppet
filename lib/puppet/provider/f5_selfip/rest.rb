require 'puppet/provider/f5'
require 'puppet/type/f5_node'
require 'json'

Puppet::Type.type(:f5_selfip).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    selfips = Puppet::Provider::F5.call('/mgmt/tm/net/self')
    return [] if selfips.nil?

    selfips.each do |selfip|
      portlockdown = []
      unless selfip['allowService'].nil?
        if selfip['allowService'].is_a? (String)
          portlockdown = selfip['allowService']
        else
          selfip['allowService'].each do |service|
            portlockdown << service
          end
        end
      end
      create = {
        ensure:                 :present,
        name:                   selfip['fullPath'],
        vlan:                   selfip['vlan'],
        inherit_traffic_group:  selfip['inheritedTrafficGroup'],
        traffic_group:          selfip['trafficGroup'],
        address:                selfip['address'],
        port_lockdown:          portlockdown,
      }

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

  def message(object)
    # Allows us to pass in resources and get all the attributes out
    # in the form of a hash.
    message = object.to_hash

    map = {
      :'inherit_traffic_group'  => :inheritedTrafficGroup,
      :'traffic_group'          => :trafficGroup,
      :'port_lockdown'          => :allowService,
    }
    message = rename_keys(map, message)
    message = create_message(basename, partition, message)

    message.to_json
  end

  def flush
    if @property_hash != {}
      result = Puppet::Provider::F5.put("/mgmt/tm/net/self/#{api_name}", message(@property_hash))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    result = Puppet::Provider::F5.post("/mgmt/tm/net/self", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    result = Puppet::Provider::F5.delete("/mgmt/tm/net/self/#{api_name}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
