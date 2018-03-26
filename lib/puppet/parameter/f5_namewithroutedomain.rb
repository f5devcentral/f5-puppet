require 'puppet/parameter'
require File.join(File.dirname(__FILE__), 'f5_name.rb')

class Puppet::Parameter::F5NameWithRouteDomain < Puppet::Parameter::F5Name
  validate do |value|
    fail ArgumentError, "#{name} must be a String" unless value.is_a?(String)
    fail ArgumentError, "#{name} must match the pattern /Partition/name" unless value.match(%r{/[\w\.-]+/[\w\.-]+(\%\d+)?$})
  end
end
