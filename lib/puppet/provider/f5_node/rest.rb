require 'puppet/provider/f5'

Puppet::Type.type(:f5_node).provide(:f5_node, :parent => Puppet::Provider::F5) do
  def self.instances
    instances = []
    nodes = call('/mgmt/tm/ltm/node')
    nodes.each do |node|
      instances << new(:name => node["name"], :ensure => :present)
    end

    return instances
  end

  def exists?
    true
  end
end
