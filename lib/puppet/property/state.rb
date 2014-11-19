require 'puppet/property'

class Puppet::Property::F5State < Puppet::Property
  options = "<enabled|disabled|forced_offline>"
  desc "The state of the object.
  Valid options: #{options}"

  validate do |value|
    unless value.is_a?(String) && value =~ /^(enabled|disabled|forced_offline)/
      fail ArgumentError, "#{name} must be: enabled|disabled|forced_offline"
    end
  end
end
