require 'puppet/property'

class Puppet::Property::F5State < Puppet::Property
  options = "<up|down|enabled|disabled|offline|checking>'
  desc 'The state of the object.
  Valid options: #{options}"

  validate do |value|
    unless value.is_a?(String) && value =~ /^(up|down|enabled|disabled|offline|checking)/
      raise ArgumentError, "#{name} must be: #{options}"
    end
  end
end
