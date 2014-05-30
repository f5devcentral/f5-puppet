require 'puppet/parameter'

class Puppet::Parameter::F5Name < Puppet::Parameter
  options = "<string>"
  desc "The name of the object.
  Valid options: #{options}"

  validate do |value|
    unless value.is_a?(String)
      raise ArgumentError, "#{name} must be a String"
    end
  end
end
