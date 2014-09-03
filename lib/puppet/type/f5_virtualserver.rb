require 'puppet/parameter/name'
require 'puppet/property/connection_limit'
require 'puppet/property/connection_rate_limit'
require 'puppet/property/description'
require 'puppet/property/state'

Puppet::Type.newtype(:f5_virtualserver) do
  @doc = 'Manage node objects'

  apply_to_device
  ensurable

  newparam(:name, :parent => Puppet::Parameter::F5Name, :namevar => true)
  newproperty(:connection_limit, :parent => Puppet::Property::F5ConnectionLimit)
  newproperty(:connection_rate_limit, :parent => Puppet::Property::F5ConnectionRateLimit)
  newproperty(:description, :parent => Puppet::Property::F5Description)
  newproperty(:state, :parent => Puppet::Property::F5State)

  newproperty(:source) do
    # TODO: Should we validate this to an IP?
  end

  newproperty(:destination) do
    options = "{ 'host': '<string'>, 'network': '<string>' }"

    validate do |value|
      unless value.is_a?(Hash) && value['host'] && value['network']
        fail ArgumentError, "Destination: Valid options: #{options}"
      end
    end
  end

  newproperty(:service_port) do
    options = "<*|Integer>"

    validate do |value|
      fail ArgumentError, "Service_port: Valid options: #{options}" unless value =~ /^(\*|\d+)$/
      # Only check in the case of a number.
      if value =~ /\d+$/
        fail ArgumentError, "Service_port:  Must be between 1-65535" unless value.to_i.between?(1,65535)
      end
    end
  end

  newproperty(:protocol) do
    newvalues(:all, :tcp, :udp, :sctp)
  end

  newproperty(:protocol_profile_client) do
    newvalues(:'mptcp-mobile-optimized', :tcp, :'tcp-lan-optimized', :'tcp-legacy', :'tcp-mobile-optimized', :'tcp-wan-optimized', :'wam-tcp-lan-optimized', :'wam-tcp-wan-optimized', :'wom-tcp-lan-optimized', :'wom-tcp-wan-optimized')
  end

  newproperty(:protocol_profile_server) do
    options = %w( mptcp-mobile-optimized tcp tcp-lan-optimized tcp-legacy tcp-mobile-optimized tcp-wan-optimized wam-tcp-lan-optimized wam-tcp-wan-optimized wom-tcp-lan-optimized wom-tcp-wan-optimized )

    validate do |value|
      fail ArgumentError, "Protocol_profile_server: must match the pattern /Partition/name" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
      fail ArgumentError, "Protocol_profile_server: Valid options: #{options}" unless options.include?(File.basename(value))
    end
  end

  # Only one of the next five properties can be set.
  newproperty(:http_profile) do
    validate do |value|
      fail ArgumentError, "Http_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:ftp_profile) do
    validate do |value|
      fail ArgumentError, "Ftp_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:rtsp_profile) do
    validate do |value|
      fail ArgumentError, "Rtsp_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:socks_profile) do
    validate do |value|
      fail ArgumentError, "Socks_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:xml_profile) do
    validate do |value|
      fail ArgumentError, "Xml_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end


  newproperty(:stream_profile) do
    validate do |value|
      fail ArgumentError, "Stream_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:ssl_profile_client) do
    validate do |value|
      fail ArgumentError, "Ssl_profile_client: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:ssl_profile_server) do
    validate do |value|
      fail ArgumentError, "Ssl_profile_server: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:authentication_profiles) do
    validate do |value|
      fail ArgumentError, "Authentication_profiles: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:dns_profile) do
    validate do |value|
      fail ArgumentError, "Dns_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:diameter_profile) do
    validate do |value|
      fail ArgumentError, "Diameter_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:fix_profile) do
    validate do |value|
      fail ArgumentError, "Fix_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:request_adapt_profile) do
    validate do |value|
      fail ArgumentError, "Request_adapt_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:response_adapt_profile) do
    validate do |value|
      fail ArgumentError, "Response_adapt_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:sip_profile) do
    validate do |value|
      fail ArgumentError, "Sip_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:statistics_profile) do
    validate do |value|
      fail ArgumentError, "Statistics_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:vlan_and_tunnel_traffic) do
    options = "<all|{ <'enabled'|'disabled'> => [ '/Partition/object' ]}>"
    validate do |value|
      # Make sure we either have all or a hash.
      fail ArgumentError, "Vlan_and_tunnel_traffic: Valid options: #{options}" unless value =~ /^all$/ || value.is_a?(Hash)
      if value.is_a?(Hash)
        # Make sure the hash contains either enabled or disabled.
        fail ArgumentError, "Vlan_and_tunnel_traffic: Valid options: #{options}" unless value['enabled'] || value['disabled']
        # Count after validation matches the count before so all validated OK.
        if value['enabled']
          fail ArgumentError, "Vlan_and_tunnel_traffic: Valid options: #{options}" unless value['enabled'].select {|obj| obj =~  /^\/\w+\/(\w|\d|\.)+$/}.count == value['enabled'].count
        elsif value['disabled']
          fail ArgumentError, "Vlan_and_tunnel_traffic: Valid options: #{options}" unless value['disabled'].select {|obj| obj  =~ /^\/\w+\/(\w|\d|\.)+$/}.count == value['disabled'].count
        end
      end
    end
  end

  newproperty(:source_address_translation) do
    options = "<auto_map|{ 'snat' => '/Partition/pool_name'}>"
    validate do |value|
      # Make sure we either have auto_map or a hash.
      fail ArgumentError, "Source_address_translation: Valid options: #{options}" unless value =~ /^auto_map$/ || value.is_a?(Hash)
      # Make sure the hash contains 'snat' as the key.
      fail ArgumentError, "Source_address_translation: Valid options: #{options}" unless value['snat']
      # Make sure the hash value is an object.
      fail ArgumentError, "Source_address_translation: Valid options: #{options}" unless value['snat'].select {|obj| obj  =~ /^\/\w+\/(\w|\d|\.)+$/}.count == value['snat'].count
    end
  end

  # TODO: Figure out what this actually takes, I can only see None in the UI.
  newproperty(:bandwidth_controller) do
    options = "<none|{ 'bandwidth_controller' => '/Partition/pool_name'}>"
    validate do |value|
      # Make sure we either have none or a hash.
      fail ArgumentError, "Bandwidth_controller: Valid options: #{options}" unless value =~ /^none$/ || value.is_a?(Hash)
      # Make sure the hash contains 'bandwidth_controller' as the key.
      fail ArgumentError, "Bandwidth_controller: Valid options: #{options}" unless value['bandwidth_controller']
      # Make sure the hash value is an object.
      fail ArgumentError, "Bandwidth_controller: Valid options: #{options}" unless value['bandwidth_controller'].select {|obj| obj  =~ /^\/\w+\/(\w|\d|\.)+$/}.count == value['bandwidth_controller'].count
    end
  end

  newproperty(:traffic_class) do
    validate do |value|
      fail ArgumentError, "Traffic_class: Valid options: #{options}" unless value.is_a?(Array)
      fail ArgumentError, "Traffic_class: Valid options: #{options}" unless value['traffic_class'].select {|obj| obj  =~ /^\/\w+\/(\w|\d|\.)+$/}.count == value['traffic_class'].count
    end
  end

  newproperty(:connection_rate_limit_mode) do
    newvalues(:per_virtual_server, :per_virtual_server_and_source_address, :per_virtual_server_and_destination_address, :per_virtual_server_destination_and_source_address, :per_source_address, :per_destination_address, :per_source_and_destination_address)
  end

  # Only required for per_virtual_server and per_destination_address
  newproperty(:connection_rate_limit_source_mask) do
    options = "<1-32>"
    validate do |value|
      fail ArgumentError, "Connection_rate_limit_source_mask: Valid options: #{options}" unless value.to_i.between?(1,32)
    end
  end

  # Any property with a destination.
  newproperty(:connection_rate_limit_destination_mask) do
    options = "<1-32>"
    validate do |value|
      fail ArgumentError, "Connection_rate_limit_destination_mask: Valid options: #{options}" unless value.to_i.between?(1,32)
    end
  end

  newproperty(:address_translation, :parent => Puppet::Property::F5truthy) do
    truthy_property(nil, :true, :false)
  end

  newproperty(:port_translation, :parent => Puppet::Property::F5truthy) do
    truthy_property(nil, :true, :false)
  end

  newproperty(:source_port) do
    newvalues(:preserve, :preserve_strict, :change)
  end

  newproperty(:clone_pool_client) do
    options = "</Partition/Object>"
    validate do |value|
      fail ArgumentError, "Clone_pool_client: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:clone_pool_server) do
    options = "</Partition/Object>"
    validate do |value|
      fail ArgumentError, "Clone_pool_server: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:auto_last_hop) do
    newvalues(:default, :enabled, :disabled)
  end

  newproperty(:last_hop_pool) do
    options = "</Partition/Object>"
    validate do |value|
      fail ArgumentError, "Last_hop_pool: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:analytics_profile) do
    options = "</Partition/Object>"
    validate do |value|
      fail ArgumentError, "Analytics_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:nat64, :parent => Puppet::Property::F5truthy) do
    truthy_property(nil, :true, :false)
  end

  newproperty(:request_logging_profile) do
    options = "<Integer>"
    validate do |value|
      fail ArgumentError, "Request_logging_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:vs_score) do
    options = "<1-100> - Percentage"
    validate do |value|
      fail ArgumentError, "Connection_rate_limit_source_mask: Valid options: #{options}" unless value.to_i.between?(1,100)
    end
  end

  newproperty(:rewrite_profile) do
    options = "</Partition/Object>"
    validate do |value|
      fail ArgumentError, "Rewrite_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:html_profile) do
    options = "</Partition/Object>"
    validate do |value|
      fail ArgumentError, "Html_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:rate_class) do
    options = "</Partition/Object>"
    validate do |value|
      fail ArgumentError, "Rate_class: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:oneconnect_profile) do
    options = "</Partition/Object>"
    validate do |value|
      fail ArgumentError, "Oneconnect_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:ntlm_conn_pool) do #                         => # Blank for now, need to work out how to enable.
  end

  newproperty(:http_compression_profile) do #               => # Blank for now, need to work out how to enable.
  end

  newproperty(:web_acceleration_profile) do #               => # Blank for now, need to work out how to enable.
  end

  newproperty(:spdy_profile) do #                           => # Blank for now, need to work out how to enable.
  end

  newproperty(:irules) do
    options = "</Partition/Object>"
    validate do |value|
      fail ArgumentError, "Irules: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:policies) do
    options = "</Partition/Object>"
    validate do |value|
      fail ArgumentError, "Policies: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:default_pool) do
    options = "</Partition/Object>"
    validate do |value|
      fail ArgumentError, "Default_pool: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:default_persistence_profile) do
    options = "</Partition/Object>"
    validate do |value|
      fail ArgumentError, "Default_persistence_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  newproperty(:fallback_persistence_profile) do
    options = "</Partition/Object>"
    validate do |value|
      fail ArgumentError, "Fallback_persistence_profile: Valid options: #{options}" unless value =~ /^\/\w+\/(\w|\d|\.)+$/
    end
  end

  validate do
    if [self[:http_profile], self[:ftp_profile], self[:rtsp_profile], self[:socks_profile], self[:xml_profile]].select{|x| !!x}.length != 1
      fail ArgumentError, 'ERROR:  One of the `http`, `ftp`, `rtsp`, `socks`, or `xml` profiles must be set'
    end

    if [:per_virtual_server, :per_destination_address].include?(self[:connection_rate_limit_mode])
      fail ArgumentError, 'ERROR:  Connection_rate_limit_source_mask required.' unless self[:connection_rate_limit_source_mask]
    end
    if self[:connection_rate_limit_source_mask]
      if self[:connection_rate_limit_mode] != /^(per_virtual_server|per_destination_address)$/
        fail ArgumentError, 'ERROR:  Connection_rate_limit_source_mask may only be set if connection_rate_limit_mode is set to either `per_virtual_server` or `per_destination_address`'
      end
    end

    if [:per_virtual_server_and_destination_address, :per_virtual_server_destination_and_source_address, :per_destination_address, :per_source_and_destination_address].include?(self[:connection_rate_limit_mode])
      fail ArgumentError, 'ERROR:  Connection_rate_limit_destination_mask required.' unless self[:connection_rate_limit_destination_mask]
    end
    if self[:connection_rate_limit_destination_mask]
      if self[:connection_rate_limit_mode] != /^(per_virtual_server_and_destination_address|per_virtual_server_destination_and_source_address|per_destination_address|per_source_and_destination_address)$/
        fail ArgumentError, 'ERROR:  Connection_rate_limit_destination_mask may only be set if connection_rate_limit_mode is set to any of `per_virtual_server_and_destination_address`, `per_virtual_server_destination_and_source_address`, `per_destination_address`, `per_source_and_destination_address`'
      end
    end

    if [:per_virtual_server_and_source_address, :per_virtual_server_destination_and_source_address, :per_source_address, :per_source_and_destination_address].include?(self[:connection_rate_limit_mode])
      fail ArgumentError, 'ERROR:  Connection_rate_limit_source_mask required.' unless self[:connection_rate_limit_source_mask]
    end
    if self[:connection_rate_limit_source_mask]
      if self[:connection_rate_limit_mode] != /^(per_virtual_server_and_source_address|per_virtual_server_destination_and_source_address|per_source_address|per_source_and_destination_address)$/
        fail ArgumentError, 'ERROR:  Connection_rate_limit_source_mask may only be set if connection_rate_limit_mode is set to any of `per_virtual_server_and_source_address`, `per_virtual_server_destination_and_source_address`, `per_source_address`, `per_source_and_destination_address`'
      end
    end

  end

end
