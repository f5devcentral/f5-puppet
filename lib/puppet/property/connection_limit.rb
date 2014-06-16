require 'puppet/property'

class Puppet::Property::F5ConnectionLimit < Puppet::Property
  desc 'The connection limit of the object.
  Valid options: <integer>'

  validate do |value|
    unless value.to_i.is_a?(Integer)
      raise ArgumentError, "#{name} must be an Integer"
    end
  end
end
