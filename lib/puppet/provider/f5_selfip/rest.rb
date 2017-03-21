require File.join(File.dirname(__FILE__), '../f5')
Puppet::Type.type(:f5_node)
require 'json'

Puppet::Type.type(:f5_selfip).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    selfips = Puppet::Provider::F5.call_items('/mgmt/tm/net/self')
    return [] if selfips.nil?

    selfips.each do |selfip|
      portlockdown = []
      if selfip['allowService'].nil?
        portlockdown = 'none'
      else
        portlockdown = selfip['allowService']
      end
      create = {
        ensure:                 :present,
        name:                   selfip['fullPath'],
        vlan:                   selfip['vlan'],
        inherit_traffic_group:  selfip['inheritedTrafficGroup'],
        traffic_group:          selfip['trafficGroup'],
        address:                selfip['address'],
        port_lockdown:          Array(portlockdown),
      }

      instances << new(create)
    end

    instances
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

    if Array(message[:port_lockdown]) == ["all"]
      message[:port_lockdown] = "all"
    end
    if Array(message[:port_lockdown]) == ["none"]
      message[:port_lockdown] = []
    end

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
