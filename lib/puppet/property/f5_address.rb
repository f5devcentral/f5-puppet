require 'puppet/property'
require 'resolv'

class Puppet::Property::F5Address < Puppet::Property
  def self.postinit
    @doc ||= "The IP address and routing ID of the resource.
    Valid options: <ipv4|ipv6>[%<route domain id>]"
  end

  validate do |value|
    address, route_domain = value.split('%')
    unless address.match(Resolv::IPv6::Regex) || address.match(Resolv::IPv4::Regex) || address.match("any6")
      fail ArgumentError, "The address of #{name} must be an ipv4 or ipv6 address; got #{address}."
    end
    if route_domain and ! route_domain.match(/^\d+$/)
      fail ArgumentError, "The route domain of #{name} must be an integer; got #{address}."
    end
  end
end
