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


Puppet::Type.newtype(:f5_persistencecookie) do
  @doc = 'Manage cookie persistence objects'

  apply_to_device
  ensurable

  newparam(:name, :parent => Puppet::Parameter::F5Name, :namevar => true)

  newproperty(:description, :parent => Puppet::Property::F5Description)

  newproperty(:method) do
    desc "Fail Safe Action. Valid values are 'reboot' or 'restart-all'."
    newvalues(:'insert', :'passive', 'rewrite')
  end

  newproperty(:cookie_name) do
    desc "cookie_name."
  end

  newproperty(:httponly, :parent => Puppet::Property::F5truthy) do
    truthy_property("Valid values are 'enabled' or 'disabled'.")
  end

  newproperty(:secure, :parent => Puppet::Property::F5truthy) do
    truthy_property("Valid values are 'enabled' or 'disabled'.")
  end

  newproperty(:always_send, :parent => Puppet::Property::F5truthy) do
    truthy_property("Valid values are 'enabled' or 'disabled'.")
  end

  newproperty(:expiration) do
    desc "expiration."
  end

  newproperty(:cookie_encryption, :parent => Puppet::Property::F5truthy) do
    truthy_property("Valid values are 'enabled' or 'disabled'.")
  end

end
