require 'puppet/property'

class Puppet::Property::F5State < Puppet::Property
  options = "<enabled|disabled|offline>'
  desc 'The state of the object.
  Valid options: #{options}"

  validate do |value|
    unless value.is_a?(String) && value =~ /^(enabled|disabled|offline)/
      raise ArgumentError, "#{name} must be: #{options}"
    end
  end
end
