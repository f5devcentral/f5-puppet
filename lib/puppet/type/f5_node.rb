require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/parameter/f5_namewithroutedomain.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_address.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_availability_requirement.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_connection_limit.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_connection_rate_limit.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_description.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_health_monitors.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_ratio.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_state.rb'))

Puppet::Type.newtype(:f5_node) do
  @doc = 'Manage node objects'

  apply_to_device
  ensurable

  newparam(:name, :parent => Puppet::Parameter::F5NameWithRouteDomain, :namevar => true)
  newproperty(:address, :parent => Puppet::Property::F5Address)
  newproperty(:state, :parent => Puppet::Property::F5State)
  newproperty(:description, :parent => Puppet::Property::F5Description)

  newproperty(:logging) do
    desc 'The logging state of the node object.
    Valid options:  <disabled|enabled|true|false>'

    newvalues(:disabled, :enabled, :true, :false)
  end

  newproperty(:health_monitors, :array_matching => :all, :parent => Puppet::Property::F5HealthMonitors)
  newproperty(:availability_requirement, :parent => Puppet::Property::F5AvailabilityRequirement)
  newproperty(:ratio, :parent => Puppet::Property::F5Ratio)
  newproperty(:connection_limit, :parent => Puppet::Property::F5ConnectionLimit)
  newproperty(:connection_rate_limit, :parent => Puppet::Property::F5ConnectionRateLimit)

  validate do
    if ! self[:address] and ! self.provider.address
      fail ArgumentError, 'ERROR: Address is a required parameter'
    end

    if ! self[:health_monitors] and self[:availability_requirement]
      fail ArgumentError, 'ERROR:  Availability cannot be set when no monitor is assigned.'
    end

    if self[:health_monitors].is_a?(Array)
      if self[:health_monitors] == ["default"] or self[:health_monitors] == ["none"]
        if self[:availability_requirement]
          fail ArgumentError, 'ERROR:  Availability cannot be managed when monitor is default or none'
        end
      elsif ! self[:availability_requirement]
        fail ArgumentError, 'ERROR:  Availability must be set when monitors are assigned.'
      end
    end

    # You can't have a minimum of more than the total number of monitors.
    if String(self[:availability_requirement]).match(/\d+/)
      if Array(self[:health_monitors]).count < Integer(self[:availability_requirement])
        fail ArgumentError, 'ERROR:  Availability count cannot be more than the total number of monitors.'
      end
    end
  end
end
