require 'puppet/property'

class Puppet::Property::F5State < Puppet::Property
  def self.postinit
    @doc ||= "The state of the object
    Valid options: <enabled|disabled|forced_offline>"
  end

  validate do |value|
    unless value.is_a?(String) && value =~ /^(enabled|disabled|forced_offline)/
      fail ArgumentError, "#{name} must be: enabled|disabled|forced_offline"
    end
  end
end
