require 'puppet/property'

class Puppet::Property::F5State < Puppet::Property
  options = "<user-up|user-down>'
  desc 'The state of the object.
  Valid options: #{options}"

  validate do |value|
    unless value.is_a?(String) && value =~ /^(user-up|user-down)/
      fail ArgumentError, "#{name} must be: up|enabled|user-down"
    end
  end
end
