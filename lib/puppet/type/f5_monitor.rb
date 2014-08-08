require 'puppet/parameter/name'
require 'puppet/property/description'
require 'puppet/property/truthy'

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
    munge do |value|
      Integer(value)
    end
  end

  newproperty(:up_interval) do
    options = '<Integer|disabled>'
    desc "How often to check the health of a resource
    Valid options: #{options}"

    validate do |value|
      unless value =~ /^\d+$/ or [:disabled, :false, :no].include?(value.to_s.to_sym)
        fail ArgumentError, "Valid options: #{options}"
      end
    end
    munge do |value|
      value = 0 if [:disabled, :false, :no].include?(value.to_s.to_sym)
      Integer(value)
    end
  end

  newproperty(:time_until_up) do
    validate do |value|
      fail ArgumentError, "Valid options: #{options}" unless value =~ /^\d+$/
    end
    munge do |value|
      Integer(value)
    end
  end

  newproperty(:timeout) do
    validate do |value|
      fail ArgumentError, "Valid options: #{options}" unless value =~ /^\d+$/
    end
    munge do |value|
      Integer(value)
    end
  end

  newproperty(:manual_resume, :parent => Puppet::Property::F5truthy) do
    truthy_property('Enabling the manual resume of a monitor and then associate the monitor with a resource, and the resource subsequently becomes unavailable, the resource remains offline until you manually re-enable it.', :enabled, :disabled)
  end

  newproperty(:send_string) do
  end

  newproperty(:receive_string) do
  end

  newproperty(:receive_disable_string) do
  end

  newproperty(:cipher_list) do
  end

  newproperty(:username) do
  end

  newproperty(:password) do
  end

  newproperty(:compatibility, :parent => Puppet::Property::F5truthy) do
    truthy_property('Enabling the Compatibility setting sets the SSL options to ALL.')
  end

  newproperty(:client_certificate) do
  end

  newproperty(:client_key) do
  end

  newproperty(:reverse, :parent => Puppet::Property::F5truthy) do
    truthy_property('Marks the pool, pool member, or node down when the test is successful. For example, if the content on your web site home page is dynamic and changes frequently, you may want to set up a reverse ECV service check that looks for the string "Error". A match for this string means that the web server was down.')
  end

  newproperty(:transparent, :parent => Puppet::Property::F5truthy) do
    truthy_property('Forces the monitor to ping through the pool, pool member, or node with which it is associated (usually a firewall) to the pool, pool member, or node. (That is, if there are two firewalls in a load balancing pool, the destination pool, pool member, or node is always pinged through the pool, pool member, or node specified; not through the pool, pool member, or node selected by the load balancing method.) In this way, the transparent pool, pool member, or node is tested: if there is no response, the transparent pool, pool member, or node is marked as down.')
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
      if value =~ /\d+$/
        fail ArgumentError, "ip_dscp:  Must be between 0-63" unless value.to_i.between?(0,63)
      end
    end
    munge do |value|
      Integer(value)
    end
  end

  newproperty(:debug, :parent => Puppet::Property::F5truthy) do
    truthy_property(nil, :yes, :no)
  end

  newproperty(:base) do
  end

  newproperty(:filter) do
  end

  newproperty(:security) do
    newvalues(:none, :ssl, :tls)
  end

  newproperty(:mandatory_attributes, :parent => Puppet::Property::F5truthy) do
    truthy_property(nil, :yes, :no)
  end

  newproperty(:chase_referrals, :parent => Puppet::Property::F5truthy) do
    truthy_property(nil, :yes, :no)
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
end
