require 'puppet/property'
require 'resolv'

class Puppet::Property::F5Address < Puppet::Property
  def self.postinit
    @doc ||= "The IP address of the resource.
    Valid options: <ipv4|ipv6>"
  end

  validate do |value|
    unless value.match(Resolv::IPv6::Regex) || value.match(Resolv::IPv4::Regex)
      fail ArgumentError, "#{name} must be: <ipv4|ipv6>."
    end
  end
end
