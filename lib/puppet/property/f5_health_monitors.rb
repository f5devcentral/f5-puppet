require 'puppet/property'
require 'resolv'

class Puppet::Property::F5HealthMonitors < Puppet::Property
  options = '<["/Partition/Objects"]|default|none>'
  desc "The health monitor(s) for the node object.
  Valid options: #{options}"

  validate do |value|
    unless value =~ /^(default|none|\/\S+)$/
      fail ArgumentError, "Valid options: #{options}"
    end
  end
  munge do |value|
    case value
    when /default/
      "default"
    when /none/
      "/Common/none"
    else
      value
    end
  end
end
