require File.join(File.dirname(__FILE__), '../f5')
require 'json'

Puppet::Type.type(:f5_passwordpolicy).provide(:rest, parent: Puppet::Provider::F5) do
  mk_resource_methods

  def self.instances
    instances = []
    instances << new(password_policy_properties)
    instances
  end

  def self.prefetch(resources)
    raise 'More than 1 f5_passwordpolicy resource in catalog' unless resources.size == 1
    resource = resources.values[0]
    resource.provider = instances.first
  end

  def self.password_policy_properties
    properties = {}
    policy = Puppet::Provider::F5.call('/mgmt/tm/auth/password-policy')

    properties[:name] = '/Common/password-policy'
    %w[expirationWarning maxDuration maxLoginFailures minDuration minimumLength passwordMemory policyEnforcement requiredLowercase requiredNumeric requiredSpecial requiredUppercase].each do |property|
      properties[property.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase.to_sym] = policy[property]
    end
    properties[:provider] = :rest
    properties
  end

  def strip_puppet_keys(hash)
    # Remove puppet keys from resource hash.
    hash.reject do |k, _|
      [:ensure, :name, :provider, Puppet::Type.metaparams].flatten.include?(k)
    end
  end

  # Expects a puppet resource property_hash and returns a payload suitable for posting to the F5 API.
  def message(resource)
    message = strip_nil_values(resource)
    message = convert_underscores(message)
    message = strip_puppet_keys(message)
    message = string_to_integer(message)
    message.to_json
  end

  def flush
    begin
      Puppet::Provider::F5.put('/mgmt/tm/auth/password-policy/',
                               message(@property_hash))
    rescue StandardError => e
      # Something went wrong.
      @property_hash = self.class.password_policy_properties
      raise e
    end
    @property_hash = self.class.password_policy_properties
  end
end
