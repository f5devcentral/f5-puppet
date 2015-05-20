require 'puppet/property'
require 'resolv'

class Puppet::Property::F5HealthMonitors < Puppet::Property
  def self.postinit
    @doc ||= 'The health monitor(s) for the node object.
    Valid options: <["/Partition/Objects"]|default|none>'
  end

  validate do |value|
    unless value =~ /^(default|none|\/[\w\.-]+\/[\w\.-]+)$/
      fail ArgumentError, 'Valid options: <["/Partition/Objects"]|default|none>'
    end
  end
end
