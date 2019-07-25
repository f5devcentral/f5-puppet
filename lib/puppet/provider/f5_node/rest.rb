require File.join(File.dirname(__FILE__), '../f5')
require 'json'

Puppet::Type.type(:f5_node).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    nodes = Puppet::Provider::F5.call_items('/mgmt/tm/ltm/node')
    return [] if nodes.nil?

    nodes.each do |node|
      state = nil
      #https://devcentral.f5.com/articles/icontrol-rest-working-with-pool-members
      if node['session'] == "monitor-enabled" or node['session'] == "user-enabled"
        state = "enabled"
      elsif node['state'] == "user-down"
        state = "forced_offline"
      else
        state = "disabled"
      end
      default_route_domain = find_default_route_domain(partition(node["fullPath"])).to_s
      if node["address"].include?("%")
        address, route_domain = node['address'].split("%")
      else
        address, route_domain = [node['address'],"0"]
      end
      if route_domain != default_route_domain
        address = "#{address}%#{route_domain}"
      end

      instances << new(
          ensure:                   :present,
          name:                     node['fullPath'],
          address:                  address,
          availability_requirement: find_availability(node['monitor']),
          connection_limit:         node['connectionLimit'].to_s,
          connection_rate_limit:    node['rateLimit'],
          description:              node['description'],
          logging:                  node['logging'],
          health_monitors:          find_monitors(node['monitor']),
          ratio:                    node['ratio'].to_s,
          state:                    state,
          )
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

  def message(object)
    # Allows us to pass in resources and get all the attributes out
    # in the form of a hash.
    message = object.to_hash

    # Map for conversion in the message.
    map = {
        :'connection-rate-limit'    => :rateLimit,
        :'health-monitors'          => :monitor,
        :'availability-requirement' => :availability,
    }

    #https://devcentral.f5.com/questions/how-do-i-enable-and-disable-pool-members-using-icontrolrest
    case message[:state]
    when 'enabled'
      message[:state] = 'user-up'
      message[:session] = 'user-enabled'
    when 'disabled'
      message[:state] = 'user-up'
      message[:session] = 'user-disabled'
    when 'forced_offline'
      message[:state] = 'user-down'
      message[:session] = 'user-disabled'
    end

    message = strip_nil_values(message)
    message = convert_underscores(message)
    message = rename_keys(map, message)
    message = create_message(basename, partition, message)
    message = string_to_integer(message)
    message = monitor_conversion(message)

    # fix to allow any6 to resolve via DNS. name should be without /partition/ prefix
    if message[:address] == 'any6'
      message[:fqdn] = { 'tmName' => message[:name], 'autopopulate' => 'enabled', 'interval' => 30 }
    end
    #Puppet.info("parameter message has value '#{message}'")

    message.to_json
  end

  def flush
    if @property_hash != {}
      # You can only pass address to create, not modifications.
      flush_message = @property_hash.reject { |k, _| k == :address }
      result = Puppet::Provider::F5.put("/mgmt/tm/ltm/node/#{api_name}", message(flush_message))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    result = Puppet::Provider::F5.post("/mgmt/tm/ltm/node", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    result = Puppet::Provider::F5.delete("/mgmt/tm/ltm/node/#{api_name}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
