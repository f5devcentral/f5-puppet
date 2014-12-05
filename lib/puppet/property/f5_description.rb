require 'puppet/property'

class Puppet::Property::F5Description < Puppet::Property
  def self.postinit
    @doc ||= 'The description of the node object.
    Valid options: <string>'
  end

  validate do |value|
    unless value.is_a?(String)
      raise ArgumentError, "#{name} must be a String"
    end
  end
end
