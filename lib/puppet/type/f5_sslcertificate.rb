require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/parameter/f5_name.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_address.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_availability_requirement.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_connection_limit.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_connection_rate_limit.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_description.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_health_monitors.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_ratio.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_state.rb'))

Puppet::Type.newtype(:f5_sslcertificate) do
  @doc = 'Import SSL Certificates'

  apply_to_device
  ensurable

  newparam(:name, :parent => Puppet::Parameter::F5Name, :namevar => true)

  newproperty(:description, :parent => Puppet::Property::F5Description)

  newproperty(:certificate_name) do
    desc "keyname"
  end

  newproperty(:from_local_file) do
    desc "from_local_file"
  end

end
