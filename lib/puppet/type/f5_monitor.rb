require 'puppet/parameter/f5_name'
require 'puppet/property/f5_description'
require 'puppet/property/f5_truthy'

Puppet::Type.newtype(:f5_monitor) do
  @doc = 'Manage monitor objects. Docs at https://support.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/ltm_configuration_guide_10_0_0/ltm_appendixa_monitor_types.html#1172375'

  apply_to_device
  ensurable

  feature :external, "External command functionality"
  feature :strings, "Send/receive string functionality"
  feature :ssl, "SSL functionality"
  feature :reverse, "Reverse test functionality"
  feature :dscp, "DSCP functionality"
  feature :auth, "Authentication functionality"
  feature :ldap, "LDAP functionality"
  feature :debug, "Debug functionality"
  feature :sip, "SIP functionality"
  feature :transparent, "Pass-through functionality"

  newparam(:name, :parent => Puppet::Parameter::F5Name, :namevar => true)
  newproperty(:description, :parent => Puppet::Property::F5Description)

  newproperty(:interval) do
    options = "<Integer>"
    desc "How often in seconds to send a request
    Valid options: #{options}"
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
    desc "Allows the system to delay the marking of a pool member or node as up for some number of seconds after receipt of the first correct response."
    validate do |value|
      fail ArgumentError, "Valid options: #{options}" unless value =~ /^\d+$/
    end
    munge do |value|
      Integer(value)
    end
  end

  newproperty(:timeout) do
    desc "If a pool member or node being checked does not respond within a specified timeout period, or the status of a node indicates that performance is degraded."
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

  newproperty(:send_string, :required_features => :strings) do
    desc "The text string that the monitor sends to the target resource. Eg: GET / HTTP/1.0\\n\\n"
  end

  newproperty(:receive_string, :required_features => :strings) do
    desc "A regular expression that represents the text string that the monitor looks for in the returned resource"
  end

  newproperty(:receive_disable_string, :required_features => :strings) do
    desc "A regular expression that represents the text string that the monitor looks for in the returned resource. Use a Receive String value together with a Receive Disable String value to match the value of a response from the origin web server and create one of three states for a pool member or node: Up (Enabled), when only Receive String matches the response; Up (Disabled), when only Receive Disable String matches the response; or Down, when neither Receive String nor Receive Disable String matches the response."
  end

  newproperty(:cipher_list, :required_features => :ssl) do
    desc "A list of ciphers in the Cipher List field that match those of the client sending a request, or of the server sending a response."
  end

  newproperty(:username, :required_features => :auth) do
    desc "A user name for the monitor's authentication when checking a resource."
  end

  newproperty(:password, :required_features => :auth) do
    desc "A password for the monitor's authentication when checking a resource."
  end

  newproperty(:compatibility, :parent => Puppet::Property::F5truthy) do
    truthy_property('Enabling the Compatibility setting sets the SSL options to ALL.')
  end

  newproperty(:client_certificate, :required_features => :ssl) do
    desc "Specifies a client certificate that the monitor sends to the target SSL server."
  end

  newproperty(:client_key, :required_features => :ssl) do
    desc "Specifies a key for a client certificate that the monitor sends to the target SSL server."
  end

  newproperty(:reverse, :required_features => :reverse, :parent => Puppet::Property::F5truthy) do
    truthy_property('Marks the pool, pool member, or node down when the test is successful.')
  end

  newproperty(:transparent, :required_features => :transparent, :parent => Puppet::Property::F5truthy) do
    truthy_property('Forces the monitor to ping through the pool, pool member, or node with which it is associated (usually a firewall) to the pool, pool member, or node.')
  end

  newproperty(:alias_address) do
    options = '<ipv4|ipv6>'
    desc "Specifies the destination IP address that the monitor checks.
    Valid options: #{options}"

    validate do |value|
      unless value.match(Resolv::IPv6::Regex) || value.match(Resolv::IPv4::Regex) || value =~ /^\*$/
        fail ArgumentError, "#{name} must be: #{options}."
      end
    end
  end

  newproperty(:alias_service_port) do
    desc "Specifies the destination port that the monitor checks."
    validate do |value|
      fail ArgumentError, "Valid options: #{options}" unless value =~ /^(\*|\d+)$/
      # Only check in the case of a number.
      if value =~ /\d+$/
        fail ArgumentError, "Alias_service_port:  Must be between 1-65535" unless value.to_i.between?(1,65535)
      end
    end
  end

  newproperty(:ip_dscp, :required_features => :dscp) do
    desc "ToS or DSCP bits for traffic that you are optimizing. Set the IP DSCP setting for appropriate TCP profiles to pass. The default value is 0, which clears the ToS bits for all traffic using that profile."
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

  newproperty(:parent_monitor) do
    desc "Specifies the parent predefined or user-defined monitor."
    validate do |value|
      unless value == 'none' || value.match(%r{^/\w+/[\w\.-]+$})
        fail ArgumentError, "#{name} must be: 'none' or '/Partition/name'; got #{value.inspect}"
      end
    end
  end
  newproperty(:debug, :required_features => :debug, :parent => Puppet::Property::F5truthy) do
    truthy_property("Debug option for LDAP, SIP, and UDP monitors", :yes, :no)
  end

  newproperty(:base, :required_features => :ldap) do
    desc "LDAP base for LDAP monitor"
  end

  newproperty(:filter, :required_features => :ldap) do
    desc "LDAP filter for LDAP monitor"
  end

  newproperty(:security, :required_features => :ldap) do
    desc "LDAP security for LDAP monitor. Valid options: none, ssl, tls"
    newvalues(:none, :ssl, :tls)
  end

  newproperty(:mandatory_attributes, :required_features => :ldap, :parent => Puppet::Property::F5truthy) do
    truthy_property("LDAP mandatory attributes for LDAP monitor", :yes, :no)
  end

  newproperty(:chase_referrals, :required_features => :ldap, :parent => Puppet::Property::F5truthy) do
    truthy_property("LDAP chase referrals for LDAP monitor", :yes, :no)
  end

  newproperty(:external_program, :required_features => :external) do
    desc "Command to run for external monitor."
  end

  newproperty(:arguments, :required_features => :external) do
    desc "Command arguments for external monitor."
  end

  # Validate it's an array globally.
  newproperty(:variables, :required_features => :external) do
    #validate do |value|
    #  fail ArgumentError, "Variables must be a hash of key=>value pairs." unless value.is_a?(Hash)
    #end
  end

  newproperty(:mode, :required_features => :sip) do
    desc "SIP mode for SIP monitor. Valid options: tcp, udp, tls, sips"
    newvalues(:tcp, :udp, :tls, :sips)
  end

  newproperty(:additional_accepted_status_codes, :required_features => :sip, :array_matching => :all) do
    options = '<*|any|100-999>'
    desc "SIP accepted status codes. Valid options: #{options}"
    validate do |value|
      unless ['*', 'any', 'none'].include?(value) or value.to_i.between?(100,999)
        fail ArgumentError, "Valid options: #{options}"
      end
    end
  end

  newproperty(:additional_rejected_status_codes, :required_features => :sip, :array_matching => :all) do
    options = '<*|any|100-999>'
    desc "SIP rejected status codes. Valid options: #{options}"
    validate do |value|
      unless ['*', 'any', 'none'].include?(value) or value.to_i.between?(100,999)
        fail ArgumentError, "Valid options: #{options}"
      end
    end
  end

  # Validate it's an array globally.
  newproperty(:header_list, :required_features => :sip, :array_matching => :all) do
    desc "Headers for SIP monitor. Accepts an array of values."
  end

  newproperty(:sip_request, :required_features => :sip) do
    desc "The request to be sent by the SIP monitor."
  end
end
