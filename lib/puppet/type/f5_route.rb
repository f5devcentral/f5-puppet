require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/parameter/f5_name.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_description.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_truthy.rb'))

Puppet::Type.newtype(:f5_route) do
  @doc = 'Manage route objects'

  apply_to_device
  ensurable

  newparam(:name) do
    def self.postinit
      @doc ||= "The name of the object.
      Valid options: <String>"
    end

    validate do |value|
      fail ArgumentError, "#{name} must be a String" unless value.is_a?(String)
    end

    isnamevar

  end

  newproperty(:description, :parent => Puppet::Property::F5Description)
        
  newproperty(:gw) do
    desc "Specifies the router for the system to use when forwarding packets to the destination host or network."
  end

  newproperty(:network) do
    desc "Specifies an IP address for the Destination column of the routing table."
  end

  newproperty(:mtu) do
    desc "MTU. Valid range: 0 - 65535."
    munge do |value|
      Integer(value)
    end

    validate do |value|
      fail ArgumentError, "Valid range: 0 - 65535" unless (value =~ /^\d+$/ and Integer(value) >= 0 and Integer(value) <= 65535)
    end
  end

 newproperty(:pool) do
    desc "Specifies a gateway pool, which allows multiple, load-balanced gateways to be used for the route."
  end

 newproperty(:tm_interface) do
    desc "Specifies a VLAN for the route. This can be a VLAN or VLAN group."
  end
        
end
