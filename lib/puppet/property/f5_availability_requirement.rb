require 'puppet/property'
require 'resolv'

class Puppet::Property::F5AvailabilityRequirement < Puppet::Property
  options = '<all|Integer>'
  desc "The availability requirement (number of health monitors) that must
  be available.
  Valid options: #{options}"

  validate do |value|
    unless value =~ /^(all|\d+)$/
      fail ArgumentError, "Valid options: #{options}"
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
