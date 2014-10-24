require 'puppet/provider/f5'

Puppet::Type.type(:f5_virtualserver).provide(:stateless, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    virtualservers = Puppet::Provider::F5.call('/mgmt/tm/ltm/virtual')
    return [] if virtualservers.nil?
    virtualservers = virtualservers.select do |vs|
      vs['stateless'] == true
    end

    virtualservers.each do |vserver|
      destination_address = vserver['destination'].match(%r{/([^/]+):})[1]
      destination_port    = vserver['destination'].match(%r{:(\d+)$})[1]
      destination_port    = "*" if destination_port == 0
      if vserver["vlansEnabled"]
        vlan_and_tunnel_traffic = { "enabled" => vserver["vlans"], }
      elsif vserver["vlansDisabled"] and vserver["vlans"]
        vlan_and_tunnel_traffic = { "disabled" => vserver["vlans"], }
      else
        # And vlansDisable is always true here anyway
        vlan_and_tunnel_traffic = "all"
      end

      applied_profiles = vserver["profilesReference"]["items"].inject({}) do |memo,profile|
        warning "Can't find #{profile.inspect}" if find_profile_type(profile["fullPath"]).nil?
        memo.merge!({ find_profile_type(profile["fullPath"]) => Array(memo[find_profile_type(profile["fullPath"])]) << profile })
      end

      rate_limit_mode = {
        'object'                    => :per_virtual_server,
        'object-source'             => :per_virtual_server_and_source_address,
        'object-destination'        => :per_virtual_server_and_destination_address,
        'object-source-destination' => :per_virtual_server_destination_and_source_address,
        'source'                    => :per_source_address,
        'destination'               => :per_destination_address,
        'source-destination'        => :per_source_and_destination_address,
      }
      connection_rate_limit_mode = rate_limit_mode[vserver["rateLimitMode"]] || vserver["rateLimitMode"]
      case vserver["sourceAddressTranslation"]["type"]
      when 'automap'
        source_address_translation = 'automap'
      when 'lsn'
        source_address_translation = { 'lsn' => vserver["sourceAddressTranslation"]["pool"] }
      when 'snat'
        source_address_translation = { 'snat' => vserver["sourceAddressTranslation"]["pool"] }
      else
        source_address_translation = nil
      end

      case vserver["sourcePort"]
      when 'preserve-strict'
        source_port = :preserve_strict
      else
        source_port = vserver["sourcePort"]
      end

      instances << new(
        name:                                   vserver["fullPath"],
        ensure:                                 :present,
        address_status:                         vserver["addressStatus"],
        auto_last_hop:                          vserver["autoLasthop"],
        #vserver["cmpEnabled"],
        connection_limit:                       vserver["connectionLimit"],
        description:                            vserver["description"],
        destination_address:                    destination_address,
        destination_mask:                       vserver["mask"],
        service_port:                           destination_port,
        #vserver["enabled"]
        vs_score:                               vserver["gtmScore"],
        protocol:                               vserver["ipProtocol"],
        last_hop_pool:                          vserver["lastHopPool"],
        #vserver["mobileAppTunnel"]
        nat64:                                  vserver["nat64"],
        connection_rate_limit:                  vserver["rateLimit"],
        connection_rate_limit_destination_mask: vserver["rateLimitDstMask"],
        connection_rate_limit_source_mask:      vserver["rateLimitSrcMask"],
        connection_rate_limit_mode:             connection_rate_limit_mode,
        source:                                 vserver["source"],
        source_address_translation:             source_address_translation,
        source_port:                            source_port,
        #vserver["synCookieStatus"]
        address_translation:                    vserver["translateAddress"],
        port_translation:                       vserver["translatePort"],
        vlan_and_tunnel_traffic:                vlan_and_tunnel_traffic,
        #definition:                             vserver["apiAnonymous"],
        statistics_profile:                     ((applied_profiles["statistics"]||[]).first || {})["fullPath"],
        #analytics_profile:                      aoeu,
        default_pool:                           vserver["pool"],
        stateless:                              true,
      )
    end

    instances
  end

  def self.prefetch(resources)
    vservers = instances
    resources.keys.each do |name|
      if provider = vservers.find { |vserver| vserver.name == name }
        resources[name].provider = provider
      end
    end
  end

  def basename
    File.basename(resource[:name])
  end

  def partition
    File.dirname(resource[:name])
  end

  def message(object)
    # Allows us to pass in resources and get all the attributes out
    # in the form of a hash.
    message = object.to_hash
    message[:stateless] = true

    # Map for conversion in the message.
    map = {
      :'vs-score'                               => :'gtm-score',
      :protocol                                 => :'ip-protocol',
      :'connection-rate-limit'                  => :'rate-limit',
      :'connection-rate-limit-mode'             => :'rate-limit-mode',
      :'connection-rate-limit-destination-mask' => :'rate-limit-dst-mask',
      :'connection-rate-limit-source-mask'      => :'rate-limit-src-mask',
      :'address-translation'                    => :'translate-address',
      :'auto-last-hop'                          => :'auto-lasthop',
      :'destination-mask'                       => :mask,
      :'port-translation'                       => :'translate-port',
      :'default-pool'                           => :pool,
    }

    message[:destination] = "#{partition}/#{message[:destination_address]}:#{message[:service_port]}"
    message.delete(:destination_address)
    message.delete(:service_port)

    message[:source_address_translation] = { "type" => message[:source_address_translation] } if message[:source_address_translation]

    if message[:vlan_and_tunnel_traffic]
      if message[:vlan_and_tunnel_traffic] == 'all'
        message[:vlans_disabled] = true
      elsif message[:vlan_and_tunnel_traffic].key?("enabled")
        message[:vlans_enabled] = true
        message[:vlans] = message[:vlan_and_tunnel_traffic]["enabled"]
      elsif message[:vlan_and_tunnel_traffic].key?("disabled")
        message[:vlans_disabled] = true
        message[:vlans] = message[:vlan_and_tunnel_traffic]["disabled"]
      end
      message.delete(:vlan_and_tunnel_traffic)
    end

    message[:profiles] = Array.new
    message[:profiles] << { :name => message[:statistics_profile] } if message[:statistics_profile]
    message.delete(:statistics_profile)

    message[:source_port] = 'preserve-strict' if message[:source_port] == :preserve_strict

    message = message.reject { |k,v| v.nil? }

    rate_limit_mode = {
      :per_virtual_server                                => 'object',
      :per_virtual_server_and_source_address             => 'object-source',
      :per_virtual_server_and_destination_address        => 'object-destination',
      :per_virtual_server_destination_and_source_address => 'object-source-destination',
      :per_source_address                                => 'source',
      :per_destination_address                           => 'destination',
      :per_source_and_destination_address                => 'source-destination',
    }
    message[:connection_rate_limit_mode] = rate_limit_mode[message[:connection_rate_limit_mode]] || message[:connection_rate_limit_mode]

    # We need to rename some properties back to the API.
    message = convert_underscores(message)
    message = rename_keys(map, message)
    message = string_to_integer(message)

    message = create_message(basename, partition, message)

    message.to_json
  end

  def flush
    if @property_hash != {}
      result = Puppet::Provider::F5.put("/mgmt/tm/ltm/virtual/#{basename}", message(@property_hash))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @create_elements = true
    result = Puppet::Provider::F5.post("/mgmt/tm/ltm/virtual", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    result = Puppet::Provider::F5.delete("/mgmt/tm/ltm/virtual/#{basename}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
