require 'puppet/property'

class Puppet::Property::F5Profile < Puppet::Property
  desc "A profile that may be added to the virtualserver.
  Valid options: none or /Partition/name"

  validate do |value|
    unless value == 'none' || value.match(%r{^/\w+/[\w\.-]+$})
      fail ArgumentError, "#{name} must be: 'none' or '/Partition/name'; got #{value.inspect}"
    end
  end
end
