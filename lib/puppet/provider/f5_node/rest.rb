require 'puppet/provider/f5'
require 'json'

Puppet::Type.type(:f5_node).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    nodes = Puppet::Provider::F5.call('/mgmt/tm/ltm/node')
    nodes.each do |node|
      instances << new(
        ensure:                :present,
        name:                  node['fullPath'],
        address:               node['address'],
        availability:          find_availability(node['monitor']),
        connection_limit:      node['connectionLimit'].to_s,
        connection_rate_limit: node['rateLimit'],
        description:           node['description'],
        logging:               node['logging'],
        monitor:               find_objects(node['monitor']),
        ratio:                 node['ratio'].to_s,
        state:                 node['state']
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

  def basename
    File.basename(resource[:name])
  end

  def partition
    File.dirname(resource[:name])
  end

  def message(object)
    # Allows us to pass in resources and get all the attributes out
    # in the form of a hash.
    hash = object.to_hash

    # Map for conversion in the message.
    map = {
      connection_limit: :connectionLimit,
      connection_rate_limit: :rateLimit
    }

    # Create the message by stripping :present.
    message             = hash.reject { |k, _| [:ensure, :loglevel, :provider].include?(k) }
    message[:name]      = basename
    message[:partition] = partition

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

    # If monitor is an array then we need to rebuild the message.
    if message[:monitor].is_a?(Array)
      message.reject! { |k, _| [:monitor, :availability].include?(k) }
      message[:monitor] = "min #{hash[:availability]} of #{hash[:monitor].join(' ')}"
    end

    message.to_json
  end

  def flush
    if @property_hash != {}
      # You can only pass address to create, not modifications.
      flush_message = @property_hash.reject { |k, _| k == :address }
      result = Puppet::Provider::F5.put("/mgmt/tm/ltm/node/#{basename}", message(flush_message))
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
    result = Puppet::Provider::F5.delete("/mgmt/tm/ltm/node/#{basename}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
