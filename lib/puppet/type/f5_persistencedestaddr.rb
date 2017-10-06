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


Puppet::Type.newtype(:f5_persistencedestaddr) do
  @doc = 'Manage f5_persistencedestaddr persistence objects'

  apply_to_device
  ensurable

  newparam(:name, :parent => Puppet::Parameter::F5Name, :namevar => true)

  newproperty(:description, :parent => Puppet::Property::F5Description)

  newproperty(:match_across_services, :parent => Puppet::Property::F5truthy) do
    truthy_property("Valid values are 'enabled' or 'disabled'.")
  end

  newproperty(:match_across_virtuals, :parent => Puppet::Property::F5truthy) do
    truthy_property("Valid values are 'enabled' or 'disabled'.")
  end

  newproperty(:match_across_pools, :parent => Puppet::Property::F5truthy) do
    truthy_property("Valid values are 'enabled' or 'disabled'.")
  end

  newproperty(:hash_algorithm) do
    desc "hash_algorithm."
    newvalues(:default, :'carp')
  end

  newproperty(:mask) do
    desc "mask."
  end

  newproperty(:timeout) do
    desc "timeout."
  end

  newproperty(:override_connection_limit, :parent => Puppet::Property::F5truthy) do
    truthy_property("Valid values are 'enabled' or 'disabled'.")
  end

end
