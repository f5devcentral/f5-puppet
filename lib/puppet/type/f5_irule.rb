require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/parameter/f5_name.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_truthy.rb'))

Puppet::Type.newtype(:f5_irule) do
  @doc = 'Manage irule objects'

  apply_to_device
  ensurable

  newparam(:name, :parent => Puppet::Parameter::F5Name, :namevar => true)

  newproperty(:definition) do
    desc 'iRule text containing event declarations consisting of TCL code that is executed when an event occurs'
  end

  newproperty(:verify_signature, :parent => Puppet::Property::F5truthy) do
    truthy_property('Verify signature contained in the definition.', :true, :false)
  end

  validate do
    if self[:verify_signature] == :true
      if ! self[:definition].match(/definition-signature/)
        raise ArgumentError, "#{name} has verify_signature set to true, but the definition does not contain a signature."
      end
    end
  end
end
