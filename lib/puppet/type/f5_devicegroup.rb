require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/parameter/f5_name.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_address.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_availability_requirement.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_connection_limit.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_connection_rate_limit.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_description.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_health_monitors.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_ratio.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_state.rb'))

require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_truthy.rb'))

Puppet::Type.newtype(:f5_devicegroup) do
  @doc = 'Manage device group objects'

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

  newproperty(:type) do
    desc "Group type. Valid values are 'sync-only' or 'sync-failover'."
    newvalues(:'sync-only', :'sync-failover')
  end

  #newproperty(:auto_sync) do
  #  desc "Auto sync. Valid values are 'default', 'enabled' or 'disabled'."
  #  newvalues(:default, :enabled, :disabled)
  #end

  newproperty(:auto_sync, :parent => Puppet::Property::F5truthy) do
    desc "auto_sync. Valid values are 'enabled' or 'disabled'."
    truthy_property('Fail Safe')
  end

  newproperty(:devices, :array_matching => :all) do
    desc "Devices that this dg resource is bound to. "
  end

  #newproperty(:servers, :array_matching => :all) do
  #  desc "Server list. Accepts an array of values."
  #  # TODO: Should we validate this?
  #end

  #newproperty(:timezone) do
  #  desc "timezone"
  #  # TODO: Should we validate this?
  #end
end
