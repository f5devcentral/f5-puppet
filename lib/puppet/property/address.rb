require 'puppet/property'
require 'resolv'

class Puppet::Property::F5Address < Puppet::Property
  options = '<ipv4|ipv6>'
  desc "The IP address of the resource.
  Valid options: #{options}"

  validate do |value|
    unless value.match(Resolv::IPv6::Regex) || value.match(Resolv::IPv4::Regex)
      fail ArgumentError, "#{name} must be: #{options}."
    end
  end
end
