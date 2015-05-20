require 'puppet/property'

class Puppet::Property::F5Profile < Puppet::Property
  def self.postinit
    @doc ||= "A profile that may be added to the virtualserver.
    Valid options: none or /Partition/name"
  end

  validate do |value|
    unless value =~ /^(none|\/[\w\.-]+\/(\w|\.)+)$/
      fail ArgumentError, "#{name} must be: 'none' or '/Partition/name'; got #{value.inspect}"
    end
  end
end
