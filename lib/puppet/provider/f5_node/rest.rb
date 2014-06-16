require 'puppet/provider/f5'
require 'json'

Puppet::Type.type(:f5_node).provide(:rest, :parent => Puppet::Provider::F5) do

  def self.instances
    instances = []
    nodes = call('/mgmt/tm/ltm/node')
    nodes.each do |node|
      instances << new(
        :ensure                => :present,
        :name                  => node["fullPath"],
        :availability          => find_availability(node["monitor"]),
        :connection_limit      => node["connectionLimit"],
        :connection_rate_limit => node["rateLimit"],
        :description           => node["description"],
        :logging               => node["logging"],
        :monitors              => find_objects(node["monitor"]),
        :ratio                 => node["ratio"],
        :state                 => node["state"],
      )
    end

    return instances
  end

  def flush
    require 'pry'
    binding.pry
    name = @property_hash[:name].split('/')

    message = {}
    if @property_hash
      post('/mgmt/tm/ltm/node', @property_hash.to_json)
    end
  end

  def exists?
    true
  end

  mk_resource_methods

end
