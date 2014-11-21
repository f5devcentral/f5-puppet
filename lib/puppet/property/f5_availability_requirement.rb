require 'puppet/property'
require 'resolv'

class Puppet::Property::F5AvailabilityRequirement < Puppet::Property
  def self.postinit
    @doc ||= "The availability requirement (number of health monitors) that must
    be available.
    Valid options: <all|Integer>"
  end

  validate do |value|
    unless value =~ /^(all|\d+)$/
      fail ArgumentError, "Valid options: <all|Integer>"
    end
  end
  munge do |value|
    case value
    when "all"
      "all"
    else
      Integer(value)
    end
  end
end
