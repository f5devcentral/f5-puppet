Puppet::Type.newtype(:f5_passwordpolicy) do
  @doc = 'Sets the password policy on the BIG-IP system.'

  apply_to_device if Facter.value(:url).nil?

  newparam(:name, namevar: true) do
  end

  newproperty(:expiration_warning) do
    newvalues(/^\d+$/)
    munge { |value| Integer(value) }
  end

  newproperty(:max_duration) do
    newvalues(/^\d+$/)
    munge { |value| Integer(value) }
  end

  newproperty(:max_login_failures) do
    newvalues(/^\d+$/)
    munge { |value| Integer(value) }
  end

  newproperty(:min_duration) do
    newvalues(/^\d+$/)
    munge { |value| Integer(value) }
  end

  newproperty(:minimum_length) do
    newvalues(/^\d+$/)
    munge { |value| Integer(value) }
  end

  newproperty(:password_memory) do
    newvalues(/^\d+$/)
    munge { |value| Integer(value) }
  end

  newproperty(:policy_enforcement) do
    munge do |value|
      value = value.downcase if value.respond_to? :downcase

      case value
      when true, 'true', 'enabled'
        'enabled'
      when false, 'false', 'disabled'
        'disabled'
      else
        raise ArgumentError, 'expected a boolean value, \'enabled\' or \'disabled\''
      end
    end
  end

  newproperty(:required_lowercase) do
    newvalues(/^\d+$/)
    munge { |value| Integer(value) }
  end

  newproperty(:required_numeric) do
    newvalues(/^\d+$/)
    munge { |value| Integer(value) }
  end

  newproperty(:required_special) do
    newvalues(/^\d+$/)
    munge { |value| Integer(value) }
  end

  newproperty(:required_uppercase) do
    newvalues(/^\d+$/)
    munge { |value| Integer(value) }
  end
end
