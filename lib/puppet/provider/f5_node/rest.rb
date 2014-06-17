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

  def flush
    return false unless @property_hash

    # Map for conversion in the message.
    map = {
      connection_limit: :connectionLimit,
      connection_rate_limit: :rateLimit
    }

    # We need to seperate out the full name into components.
    name      = File.basename(resource[:name])
    partition = File.dirname(resource[:name])

    message = {
      name: name,
      partition: partition
    }

    # We need to rename some properties back to the API.
    map.each do |k, v|
      next unless @property_hash[k]
      value = @property_hash[k]
      @property_hash.delete(k)
      @property_hash[v] = value
    end

    # Apply transformations
    @property_hash.each do |k, v|
      @property_hash[k] = Integer(v) if Puppet::Provider::F5.integer?(v)
    end

    # Exclude monitor as this has a unique syntax.
    message.merge!(@property_hash)

    # Handle monitor specially.
    if @property_hash[:monitor].is_a?(Array)
      message.reject! { |k, _| [:monitor, :availability].include?(k) }
      message[:monitor] = "min #{@property_hash[:availability]} of #{@property_hash[:monitor].join(' ')}"
    end

    # We don't want to pass an ensure into the final message.
    message.reject! { |k, _| k == :ensure }
    require 'pry';binding.pry
    Puppet::Provider::F5.put("/mgmt/tm/ltm/node/#{name}", message.to_json)
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  mk_resource_methods

end
