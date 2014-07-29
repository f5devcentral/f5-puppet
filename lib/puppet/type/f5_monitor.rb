require 'puppet/parameter/name'
require 'puppet/property/description'

Puppet::Type.newtype(:f5_monitor) do
  @doc = 'Manage monitor objects'

  apply_to_device
  ensurable

  newparam(:name, :parent => Puppet::Parameter::F5Name, :namevar => true)
  newproperty(:description, :parent => Puppet::Property::F5Description)

  newproperty(:interval) do
    validate do |value|
      fail ArgumentError, "Valid options: #{options}" unless value =~ /^\d+$/
    end
  end

  newproperty(:up_interval) do
    validate do |value|
      unless value =~ /^\d+$/ or [:disabled, :enabled, :true, :false].include?(valid)
        fail ArgumentError, "Valid options: #{options}"
      end
    end
  end

  newproperty(:time_until_up) do
    validate do |value|
      fail ArgumentError, "Valid options: #{options}" unless value =~ /^\d+$/
    end
  end

  newproperty(:timeout) do
    validate do |value|
      fail ArgumentError, "Valid options: #{options}" unless value =~ /^\d+$/
    end
  end

  newproperty(:manual_resume) do
    newvalues(:yes, :no, :true, :false, :enabled, :disabled)
  end

  newproperty(:send_string) do
  end

  newproperty(:receive_string) do
  end

  newproperty(:receive_disable_string) do
  end

  newproperty(:cipher_list) do
  end

  newproperty(:user) do
  end

  newproperty(:password) do
  end

  newproperty(:compatibility) do
    newvalues(:disabled, :enabled, :true, :false)
  end

  newproperty(:client_certificate) do
  end

  newproperty(:client_key) do
  end

  newproperty(:reverse) do
    newvalues(:yes, :no, :true, :false)
  end

  newproperty(:transparent) do
    newvalues(:yes, :no, :true, :false, :enabled, :disabled)
  end

  newproperty(:alias_address) do
    options = '<ipv4|ipv6>'
    desc "The IP address of the resource.
    Valid options: #{options}"

    validate do |value|
      unless value.match(Resolv::IPv6::Regex) || value.match(Resolv::IPv4::Regex) || value =~ /^\*$/
        fail ArgumentError, "#{name} must be: #{options}."
      end
    end
  end

  newproperty(:alias_service_port) do
    validate do |value|
      fail ArgumentError, "Valid options: #{options}" unless value =~ /^(\*|\d+)$/
      # Only check in the case of a number.
      if value =~ /\d+$/
        fail ArgumentError, "Alias_service_port:  Must be between 1-65535" unless value.to_i.between?(1,65535)
      end
    end
  end

  newproperty(:ip_dscp) do
    validate do |value|
      fail ArgumentError, "Valid options: #{options}" unless value =~ /^\d+$/
    end
  end

  newproperty(:debug) do
    newvalues(:yes, :no, :true, :false)
  end

  newproperty(:base) do
  end

  newproperty(:filter) do
  end

  newproperty(:security) do
    newvalues(:none, :ssl, :tls)
  end

  newproperty(:mandatory_attributes) do
    newvalues(:yes, :no, :true, :false)
  end

  newproperty(:chase_referrals) do
    newvalues(:yes, :no, :true, :false)
  end

  newproperty(:external_program) do
  end

  newproperty(:arguments) do
  end

  # Validate it's an array globally.
  newproperty(:variables) do
    #validate do |value|
    #  fail ArgumentError, "Variables must be a hash of key=>value pairs." unless value.is_a?(Hash)
    #end
  end

  newproperty(:mode) do
    newvalues(:tcp, :udp, :tls, :sips)
  end

  newproperty(:additional_accepted_status_codes, :array_matching => :all) do
    validate do |value|
      unless ['any', 'none'].include?(value) or value =~ /\d+/
        fail ArgumentError, "Valid options: #{options}"
      end
    end
  end

  newproperty(:additional_rejected_status_codes, :array_matching => :all) do
    validate do |value|
      unless ['any', 'none'].include?(value) or value =~ /\d+/
        fail ArgumentError, "Valid options: #{options}"
      end
    end
  end

  # Validate it's an array globally.
  newproperty(:header_list, :array_matching => :all) do
  end

  newproperty(:sip_request) do
  end

  # TODO: Figure out how to validate.
  # 10.0.0.1:ssh
  newproperty(:destination) do
  end

end
