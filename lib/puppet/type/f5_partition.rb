require 'puppet/parameter/f5_name'
require 'puppet/property/f5_address'
require 'puppet/property/f5_availability_requirement'
require 'puppet/property/f5_connection_limit'
require 'puppet/property/f5_connection_rate_limit'
require 'puppet/property/f5_description'
require 'puppet/property/f5_health_monitors'
require 'puppet/property/f5_ratio'
require 'puppet/property/f5_state'

Puppet::Type.newtype(:f5_partition) do
  @doc = 'Manage partition objects'

  apply_to_device
  ensurable

  newparam(:name) do
    def self.postinit
      @doc ||= "The name of the object.
      Valid options: <String>"
    end

    validate do |value|
      fail ArgumentError, "#{name} must be a String" unless value.is_a?(String)
    end

    isnamevar

  end

  newproperty(:description, :parent => Puppet::Property::F5Description)
end
