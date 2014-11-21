require 'puppet/property'

class Puppet::Property::F5ConnectionRateLimit < Puppet::Property
  def self.postinit
    @doc ||= 'The connection rate limit of the object.
    Valid options: <Integer|disabled>'
  end

  validate do |value|
    if ! value.match(/^(\d+|disabled)$/)
      raise ArgumentError, "#{name} must be an Integer"
    end
  end
  munge do |value|
    if value == 'disabled'
      'disabled'
    else
      Integer(value)
    end
  end
end
