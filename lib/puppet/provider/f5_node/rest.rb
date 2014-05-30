require 'puppet/provider/f5'

Puppet::Type.type(:f5_node).provide(:f5_node, :parent => Puppet::Provider::F5) do
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

  def exists?
    true
  end

  mk_resource_methods
end
