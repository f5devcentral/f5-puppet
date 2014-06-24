require 'puppet/property'
require 'resolv'

class Puppet::Property::F5Availability < Puppet::Property
  options = '<all|Integer>'
  desc "The availability requirement (number of health monitors) that must
  be available.
  Valid options: #{options}"

  validate do |value|
    unless value =~ /^(all|\d+)$/
      fail ArgumentError, "Valid options: #{options}"
    end
  end
end
