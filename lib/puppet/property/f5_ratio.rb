require 'puppet/property'

class Puppet::Property::F5Ratio < Puppet::Property
  def self.postinit
    @doc ||= 'The ratio of the object.
    Valid options: <integer>'
  end

  validate do |value|
    unless value =~ /^\d+$/
      raise ArgumentError, "#{name} must be an Integer"
    end
  end
  munge do |value|
    value.to_s
  end
end
