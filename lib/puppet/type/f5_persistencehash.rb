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


Puppet::Type.newtype(:f5_persistencehash) do
  @doc = 'Manage hash persistence objects'

  apply_to_device
  ensurable

  newparam(:name, :parent => Puppet::Parameter::F5Name, :namevar => true)

  newproperty(:description, :parent => Puppet::Property::F5Description)

  newproperty(:mirror) do
    desc "mirror."
  end

  newproperty(:match_across_pools, :parent => Puppet::Property::F5truthy) do
    truthy_property("Valid values are 'enabled' or 'disabled'.")
  end

  newproperty(:match_across_services, :parent => Puppet::Property::F5truthy) do
    truthy_property("Valid values are 'enabled' or 'disabled'.")
  end

  newproperty(:match_across_virtuals, :parent => Puppet::Property::F5truthy) do
    truthy_property("Valid values are 'enabled' or 'disabled'.")
  end

 newproperty(:hash_algorithm) do
    desc "hash_algorithm."
  end

 newproperty(:hash_offset) do
    desc "hash_offset."
  end

 newproperty(:hash_length) do
    desc "hash_length."
  end

 newproperty(:hash_buffer_limit) do
    desc "hash_buffer_limit."
  end

  newproperty(:rule) do
    desc "rule."
  end

  newproperty(:timeout) do
    desc "timeout."
  end

  newproperty(:override_connection_limit, :parent => Puppet::Property::F5truthy) do
    truthy_property("Valid values are 'enabled' or 'disabled'.")
  end

end
