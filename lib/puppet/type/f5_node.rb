require 'puppet/parameter/name'
require 'puppet/property/state'
require 'puppet/property/description'
require 'puppet/property/ratio'
require 'puppet/property/connection_limit'
require 'puppet/property/connection_rate_limit'

Puppet::Type.newtype(:f5_node) do
  @doc = 'Manage node objects'

  apply_to_device
  ensurable

  newparam(:name, :parent => Puppet::Parameter::F5Name, :namevar => true)
  newproperty(:state, :parent => Puppet::Property::F5State)
  newproperty(:description, :parent => Puppet::Property::F5Description)

  newproperty(:logging) do
    desc 'The logging state of the node object.
    Valid options:  <disabled|enabled|true|false>'

    newvalues(:disabled, :enabled, :true, :false)
  end

  newproperty(:monitors, :array_matching => :all) do
    options = '<["/Partition/Objects"]|default|none>'
    desc "The health monitors for the node object.
    Valid options: #{options}"

    validate do |value|
      unless value =~ /^(default|none|\/\S+)$/
        raise ArgumentError, "Valid options: #{options}"
      end
    end
  end

  newproperty(:availability) do
    options = '<all|Integer>'
    desc "The availability requirement (number of health monitors) that must
    be available.
    Valid options: #{options}"

    validate do |value|
      unless value =~ /^(all|\d+)$/
        raise ArgumentError, "Valid options: #{options}"
      end
    end
  end

  newproperty(:ratio, :parent => Puppet::Property::F5Ratio)
  newproperty(:connection_limit, :parent => Puppet::Property::F5ConnectionLimit)
  newproperty(:connection_rate_limit, :parent => Puppet::Property::F5ConnectionRateLimit)

  validate do
    if self[:monitors].is_a?(Array) && ! self[:availability]
      raise ArgumentError 'ERROR:  Availability must be set when monitors are assigned.'
    elsif self[:monitors].is_a?(String) && self[:availability]
      raise ArgumentError 'ERROR:  Availability cannot be set when no monitors are assigned.'
    end
  end

end
