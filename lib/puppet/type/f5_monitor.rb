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

  newproperty(:send_string) do
    desc "The text string that the monitor sends to the target resource. Eg: GET / HTTP/1.0\\n\\n"
  end

  newproperty(:receive_string) do
    desc "A regular expression that represents the text string that the monitor looks for in the returned resource"
  end

  newproperty(:receive_disable_string) do
    desc "A regular expression that represents the text string that the monitor looks for in the returned resource. Use a Receive String value together with a Receive Disable String value to match the value of a response from the origin web server and create one of three states for a pool member or node: Up (Enabled), when only Receive String matches the response; Up (Disabled), when only Receive Disable String matches the response; or Down, when neither Receive String nor Receive Disable String matches the response."
  end

  newproperty(:cipher_list) do
    desc "A list of ciphers in the Cipher List field that match those of the client sending a request, or of the server sending a response."
  end

  newproperty(:username) do
    desc "A user name for the monitor's authentication when checking a resource."
  end

  newproperty(:password) do
    desc "A password for the monitor's authentication when checking a resource."
  end

  newproperty(:compatibility, :parent => Puppet::Property::F5truthy) do
    truthy_property('Enabling the Compatibility setting sets the SSL options to ALL.')
  end

  newproperty(:client_certificate) do
    desc "Specifies a client certificate that the monitor sends to the target SSL server."
  end

  newproperty(:client_key) do
    desc "Specifies a key for a client certificate that the monitor sends to the target SSL server."
  end

  newproperty(:reverse, :parent => Puppet::Property::F5truthy) do
    truthy_property('Marks the pool, pool member, or node down when the test is successful. For example, if the content on your web site home page is dynamic and changes frequently, you may want to set up a reverse ECV service check that looks for the string "Error". A match for this string means that the web server was down.')
  end

  newproperty(:transparent, :parent => Puppet::Property::F5truthy) do
    truthy_property('Forces the monitor to ping through the pool, pool member, or node with which it is associated (usually a firewall) to the pool, pool member, or node. (That is, if there are two firewalls in a load balancing pool, the destination pool, pool member, or node is always pinged through the pool, pool member, or node specified; not through the pool, pool member, or node selected by the load balancing method.) In this way, the transparent pool, pool member, or node is tested: if there is no response, the transparent pool, pool member, or node is marked as down.')
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

  newproperty(:ip_dscp) do
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

  newproperty(:debug, :parent => Puppet::Property::F5truthy) do
    truthy_property("Debug option for LDAP, SIP, and UDP monitors", :yes, :no)
  end

  newproperty(:base) do
    desc "LDAP base for LDAP monitor"
  end

  newproperty(:filter) do
    desc "LDAP filter for LDAP monitor"
  end

  newproperty(:security) do
    desc "LDAP security for LDAP monitor. Valid options: none, ssl, tls"
    newvalues(:none, :ssl, :tls)
  end

  newproperty(:mandatory_attributes, :parent => Puppet::Property::F5truthy) do
    truthy_property("LDAP mandatory attributes for LDAP monitor", :yes, :no)
  end

  newproperty(:chase_referrals, :parent => Puppet::Property::F5truthy) do
    truthy_property("LDAP chase referrals for LDAP monitor", :yes, :no)
  end

  newproperty(:external_program) do
    desc "Command to run for external monitor."
  end

  newproperty(:arguments) do
    desc "Command arguments for external monitor."
  end

  # Validate it's an array globally.
  newproperty(:variables) do
    #validate do |value|
    #  fail ArgumentError, "Variables must be a hash of key=>value pairs." unless value.is_a?(Hash)
    #end
  end

  newproperty(:mode) do
    desc "SIP mode for SIP monitor. Valid options: tcp, udp, tls, sips"
    newvalues(:tcp, :udp, :tls, :sips)
  end

  newproperty(:additional_accepted_status_codes, :array_matching => :all) do
    options = '<*|any|100-999>'
    desc "SIP accepted status codes. Valid options: #{options}"
    validate do |value|
      unless ['*', 'any', 'none'].include?(value) or value.to_i.between?(100,999)
        fail ArgumentError, "Valid options: #{options}"
      end
    end
  end

  newproperty(:additional_rejected_status_codes, :array_matching => :all) do
    options = '<*|any|100-999>'
    desc "SIP rejected status codes. Valid options: #{options}"
    validate do |value|
      unless ['*', 'any', 'none'].include?(value) or value.to_i.between?(100,999)
        fail ArgumentError, "Valid options: #{options}"
      end
    end
  end

  # Validate it's an array globally.
  newproperty(:header_list, :array_matching => :all) do
    desc "Headers for SIP monitor. Accepts an array of values."
  end

  newproperty(:sip_request) do
    desc "The request to be sent by the SIP monitor."
  end
end
