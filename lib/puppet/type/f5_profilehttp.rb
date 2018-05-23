require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/parameter/f5_name.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_address.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_availability_requirement.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_connection_limit.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_connection_rate_limit.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_description.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_health_monitors.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_ratio.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_state.rb'))

Puppet::Type.newtype(:f5_profilehttp) do
  @doc = 'Manage http profile objects'

  apply_to_device
  ensurable

  newparam(:name, :parent => Puppet::Parameter::F5Name, :namevar => true)

  newproperty(:description, :parent => Puppet::Property::F5Description)

  newproperty(:defaults_from) do
    desc "Specifies the profile that you want to use as the parent profile. Your new profile inherits all settings and values from the parent profile specified."
    validate do |value|
      fail ArgumentError, "Values must take the form /Partition/name; #{value} does not" unless value =~ /^\/[\w\.-]+\/[\w|\.-]+$/
    end
  end

  newproperty(:fallback_host) do
    desc "fallbackHost"
  end

  newproperty(:fallback_status_codes, :array_matching => :all) do
    desc "fallback_status_codes"
  end

  newproperty(:hsts_include_subdomains) do
    desc "Specifies whether to include the includeSubdomains directive in the HSTS header."
    newvalue("enabled")
    newvalue("disabled")
  end

  newproperty(:hsts_mode) do
    desc "Specifies whether to include the HSTS response header."
    newvalue("enabled")
    newvalue("disabled")
  end

  newproperty(:hsts_maximum_age) do
    desc "Specifies the maximum age to assume the connection should remain secure."
    validate do |value|
      fail ArgumentError, "Valid options: <Integer>" unless value =~ /^\d+$/ || value.is_a?(Integer)
    end
    munge do |value|
      Integer(value)
    end
  end

  newproperty(:hsts_preload) do
    desc "Specifies whether to include the preload directive in the HSTS header."
    newvalue("enabled")
    newvalue("disabled")
  end

  newproperty(:encrypt_cookies, :array_matching => :all) do
    desc "Encrypts specified cookies that the BIG-IP system sends to a client system."
  end

  newproperty(:encrypt_cookie_secret) do
    desc "Specifies a passphrase for the cookie encryption."
  end
end
