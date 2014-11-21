require 'puppet/property'
require 'resolv'

class Puppet::Property::F5HealthMonitors < Puppet::Property
  def self.postinit
    @doc ||= 'The health monitor(s) for the node object.
    Valid options: <["/Partition/Objects"]|default|none>'
  end

  validate do |value|
    unless value =~ /^(default|none|\/\S+)$/
      fail ArgumentError, 'Valid options: <["/Partition/Objects"]|default|none>'
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
