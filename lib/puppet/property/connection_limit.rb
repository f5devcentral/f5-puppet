require 'puppet/property'

class Puppet::Property::F5ConnectionLimit < Puppet::Property
  def self.postinit
    @doc ||= 'The maximum number of concurrent connections allowed for the virtual server. Setting this to 0 turns off connection limits.
    Valid options: <Integer>'
  end

  validate do |value|
    unless value =~ /^\d+$/
      raise ArgumentError, "#{name} must be an Integer"
    end
  end
  munge do |value|
    Integer(value)
  end
end
