require 'puppet/parameter'

class Puppet::Parameter::F5Name < Puppet::Parameter
  options = '<string>'
  desc "The name of the object.
  Valid options: #{options}"

  validate do |value|
    fail ArgumentError, "#{name} must be a String" unless value.is_a?(String)
    fail ArgumentError, "#{name} must match the pattern /Partition/name" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
  end
end
