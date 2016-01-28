require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/parameter/f5_name.rb'))
#require 'pp'

Puppet::Type.newtype(:f5_iapp) do
  @doc = 'Manage iApp application services on the F5 device. See [F5 documentation](https://devcentral.f5.com/wiki/iApp.HomePage.ashx) for information about iApps. The best way to get started is to create an application service in the F5 gui, then copy the manifest returned for it via `puppet resource f5_iapp`'

  apply_to_device
  ensurable

  newparam(:name, :parent => Puppet::Parameter::F5Name, :namevar => true)

  newproperty(:template) do
    desc 'Name of the iApp template to be used when creating the iApp application service.'
  end

  newproperty(:variables) do
    desc 'Hash containing iApp vars for the given template.'

    #def should_to_s(newvalue)
    #  newvalue.pretty_inspect
    #end
    #def is_to_s(newvalue)
    #  newvalue.pretty_inspect
    #end
  end

  newproperty(:tables) do
    desc 'Hash containing iApp table entries for the given template.'

    #def should_to_s(newvalue)
    #  newvalue.pretty_inspect
    #end
    #def is_to_s(newvalue)
    #  newvalue.pretty_inspect
    #end
  end
end
