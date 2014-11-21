require 'puppet/property'

class Puppet::Property::F5ConnectionLimit < Puppet::Property
  desc 'The maximum number of concurrent connections allowed for the virtual server. Setting this to 0 turns off connection limits.
  Valid options: <Integer>'

  validate do |value|
    unless value =~ /^\d+$/
      raise ArgumentError, "#{name} must be an Integer"
    end
  end
  munge do |value|
    Integer(value)
  end
end
