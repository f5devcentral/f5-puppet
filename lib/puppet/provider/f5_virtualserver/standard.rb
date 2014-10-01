require 'puppet/provider/f5'

Puppet::Type.type(:f5_virtualserver).provide(:standard, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    virtualservers = Puppet::Provider::F5.call('/mgmt/tm/ltm/virtual')
    return [] if virtualservers.nil?
    virtualservers = virtualservers.reject do |vs|
      vs['l2Forward'] == true or
      vs['ipForward'] == true or
      vs['internal'] == true or
      vs['stateless'] == true or
      vs['reject'] == true or
      vs['dhcpRelay'] == true or
      vs['profilesReference']['items'].find do |x|
        ['fastl4','fasthttp'].include?(find_profile_type(x['fullPath']))
      end
    end

    virtualservers.each do |vserver|
      destination_address = vserver['destination'].match(%r{/([^/]+):})[1]
      destination_port    = vserver['destination'].match(%r{:(\d+)$})[1]
      if vserver["vlansEnabled"]
        vlan_and_tunnel_traffic = { "enabled" => vserver["vlans"], }
      elsif vserver["vlansDisabled"] and vserver["vlans"]
        vlan_and_tunnel_traffic = { "disabled" => vserver["vlans"], }
      else
        # And vlansDisable is always true here anyway
        vlan_and_tunnel_traffic = "all"
      end

      clone_pool_client = Array(vserver["clonePools"]).collect do |pool|
        "/#{pool["partition"]}/#{pool["name"]}" if pool["context"] == "clientside"
      end.first
      clone_pool_server = Array(vserver["clonePools"]).collect do |pool|
        "/#{pool["partition"]}/#{pool["name"]}" if pool["context"] == "serverside"
      end.first

      default_persistence_profile = Array(vserver['persist']).collect do |persist|
        "/#{persist["partition"]}/#{persist["name"]}" if persist["tmDefault"]
      end.first

      applied_profiles = vserver["profilesReference"]["items"].inject({}) do |memo,profile|
        warning "Can't find #{profile.inspect}" if find_profile_type(profile["fullPath"]).nil?
        memo.merge!({ find_profile_type(profile["fullPath"]) => Array(memo[find_profile_type(profile["fullPath"])]) << profile })
      end
      #client protocol profile must be in the ipProtocol type but server
      #protocol profile may be in (tcp,sctp) if one of those is the ipProtocol
      #type
      protocol_profile_client = nil
      protocol_profile_server = nil
      if ["tcp","sctp"].include?(vserver["ipProtocol"])
        protos = Array(applied_profiles["tcp"]) + Array(applied_profiles["sctp"])
      else
        protos = Array(applied_profiles[vserver["ipProtocol"]])
      end
      protos.each do |proto|
        if proto["context"] == "all"
          protocol_profile_client = proto["fullPath"]
          protocol_profile_server = proto["fullPath"]
        elsif proto["context"] == "clientside"
          protocol_profile_client = proto["fullPath"]
        elsif proto["context"] == "serverside"
          protocol_profile_server = proto["fullPath"]
        end
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
        fallback_persistence_profile:           vserver["fallbackPersistence"],
        vs_score:                               vserver["gtmScore"],
        protocol:                               vserver["ipProtocol"],
        last_hop_pool:                          vserver["lastHopPool"],
        #vserver["mirror"]
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
        clone_pool_client:                      clone_pool_client,
        clone_pool_server:                      clone_pool_server,
        default_persistence_profile:            default_persistence_profile,
        definition:                             vserver["apiAnonymous"],
        protocol_profile_client:                protocol_profile_client,
        protocol_profile_server:                protocol_profile_server,
        authentication_profiles:                vserver["auth"],
        ssl_profile_client:                     (applied_profiles["client-ssl"       ]||[]).collect { |x| x["fullPath"] },
        ssl_profile_server:                     (applied_profiles["server-ssl"       ]||[]).collect { |x| x["fullPath"] },
        http_profile:                           ((applied_profiles["http"            ]||[]).first || {})["fullPath"],
        ftp_profile:                            ((applied_profiles["ftp "            ]||[]).first || {})["fullPath"],
        rtsp_profile:                           ((applied_profiles["rtsp"            ]||[]).first || {})["fullPath"],
        socks_profile:                          ((applied_profiles["socks"           ]||[]).first || {})["fullPath"],
        xml_profile:                            ((applied_profiles["xml"             ]||[]).first || {})["fullPath"],
        stream_profile:                         ((applied_profiles["stream"          ]||[]).first || {})["fullPath"],
        dns_profile:                            ((applied_profiles["dns"             ]||[]).first || {})["fullPath"],
        diameter_profile:                       ((applied_profiles["diameter"        ]||[]).first || {})["fullPath"],
        fix_profile:                            ((applied_profiles["fix"             ]||[]).first || {})["fullPath"],
        request_adapt_profile:                  ((applied_profiles["request-adapt"   ]||[]).first || {})["fullPath"],
        response_adapt_profile:                 ((applied_profiles["response-adapt"  ]||[]).first || {})["fullPath"],
        sip_profile:                            ((applied_profiles["sip"             ]||[]).first || {})["fullPath"],
        statistics_profile:                     ((applied_profiles["statistics"      ]||[]).first || {})["fullPath"],
        request_logging_profile:                ((applied_profiles["request-log"     ]||[]).first || {})["fullPath"],
        rewrite_profile:                        ((applied_profiles["rewrite"         ]||[]).first || {})["fullPath"],
        html_profile:                           ((applied_profiles["html"            ]||[]).first || {})["fullPath"],
        oneconnect_profile:                     ((applied_profiles["one-connect"     ]||[]).first || {})["fullPath"],
        http_compression_profile:               ((applied_profiles["http-compression"]||[]).first || {})["fullPath"],
        web_acceleration_profile:               ((applied_profiles["web-acceleration"]||[]).first || {})["fullPath"],
        spdy_profile:                           ((applied_profiles["spdy"            ]||[]).first || {})["fullPath"],
        ntlm_conn_pool:                         ((applied_profiles["ntlm"            ]||[]).first || {})["fullPath"],
        irules:                                 ((applied_profiles["rules"           ]||[]).first || {})["fullPath"],
        #analytics_profile:                      aoeu,
        bandwidth_controller:                   vserver["bwcPolicy"],
        traffic_class:                          vserver["trafficClasses"],
        rate_class:                             vserver["rateClass"],
        policies:                               (vserver["policiesReference"]["items"]||[]).collect { |x| x["fullPath"] },
        default_pool:                           vserver["pool"],
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

    # Map for conversion in the message.
    map = {
      :'authentication-profiles'                => :auth,
      :'vs-score'                               => :'gtm-score',
      :protocol                                 => :'ip-protocol',
      :'connection-rate-limit'                  => :'rate-limit',
      :'connection-rate-limit-mode'             => :'rate-limit-mode',
      :'connection-rate-limit-destination-mask' => :'rate-limit-dst-mask',
      :'connection-rate-limit-source-mask'      => :'rate-limit-src-mask',
      :'address-translation'                    => :'translate-address',
      :'fallback-persistence-profile'           => :'fallback-persistence',
      :definition                               => :'api-anonymous',
      :'bandwidth-controller'                   => :'bwc-policy',
      :'auto-last-hop'                          => :'auto-lasthop',
      :'destination-mask'                       => :mask,
      :'port-translation'                       => :'translate-port',
      :'default-persistence-profile'            => :persist,
      :'traffic-class'                          => :'traffic-classes',
      :'default-pool'                           => :pool,
    }

    message[:destination] = "#{partition}/#{message[:destination_address]}:#{message[:service_port]}"
    message.delete(:destination_address)
    message.delete(:service_port)

    message[:source_address_translation] = {
      "type" => message[:source_address_translation].first[0],
      "pool" => message[:source_address_translation].first[1],
    }

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

    message[:clone_pools] = Array.new
    message[:clone_pools] << { :name => message[:clone_pool_client], :context => "clientside" } if message[:clone_pool_client]
    message[:clone_pools] << { :name => message[:clone_pool_server], :context => "serverside" } if message[:clone_pool_server]
    message.delete(:clone_pool_client)
    message.delete(:clone_pool_server)

    message[:profiles] = Array.new
    if message[:protocol_profile_client] and message[:protocol_profile_server] and (message[:protocol_profile_client] == message[:protocol_profile_server])
      message[:profiles] << { :name => message[:protocol_profile_client], :context => :all, }
      message.delete(:protocol_profile_client)
      message.delete(:protocol_profile_server)
    else
      if message[:protocol_profile_server]
        message[:profiles] << { :name => message[:protocol_profile_server], :context => :serverside, }
        message.delete(:protocol_profile_server)
      end
      if message[:protocol_profile_client]
        message[:profiles] << { :name => message[:protocol_profile_client], :context => :clientside, }
        message.delete(:protocol_profile_client)
      end
    end
    message[:profiles] += message[:ssl_profile_client].collect { |p| { :name => p } } if message[:ssl_profile_client]
    message[:profiles] += message[:ssl_profile_server].collect { |p| { :name => p } } if message[:ssl_profile_server]
    message[:profiles] << { :name => message[:http_profile]             } if message[:http_profile]
    message[:profiles] << { :name => message[:ftp_profile]              } if message[:ftp_profile]
    message[:profiles] << { :name => message[:rtsp_profile]             } if message[:rtsp_profile]
    message[:profiles] << { :name => message[:socks_profile]            } if message[:socks_profile]
    message[:profiles] << { :name => message[:xml_profile]              } if message[:xml_profile]
    message[:profiles] << { :name => message[:stream_profile]           } if message[:stream_profile]
    message[:profiles] << { :name => message[:dns_profile]              } if message[:dns_profile]
    message[:profiles] << { :name => message[:diameter_profile]         } if message[:diameter_profile]
    message[:profiles] << { :name => message[:fix_profile]              } if message[:fix_profile]
    message[:profiles] << { :name => message[:request_adapt_profile]    } if message[:request_adapt_profile]
    message[:profiles] << { :name => message[:response_adapt_profile]   } if message[:response_adapt_profile]
    message[:profiles] << { :name => message[:sip_profile]              } if message[:sip_profile]
    message[:profiles] << { :name => message[:statistics_profile]       } if message[:statistics_profile]
    message[:profiles] << { :name => message[:request_logging_profile]  } if message[:request_logging_profile]
    message[:profiles] << { :name => message[:rewrite_profile]          } if message[:rewrite_profile]
    message[:profiles] << { :name => message[:html_profile]             } if message[:html_profile]
    message[:profiles] << { :name => message[:oneconnect_profile]       } if message[:oneconnect_profile]
    message[:profiles] << { :name => message[:http_compression_profile] } if message[:http_compression_profile]
    message[:profiles] << { :name => message[:web_acceleration_profile] } if message[:web_acceleration_profile]
    message[:profiles] << { :name => message[:spdy_profile]             } if message[:spdy_profile]
    message[:profiles] << { :name => message[:ntlm_conn_pool]           } if message[:ntlm_conn_pool]
    message[:profiles] << { :name => message[:irules]                   } if message[:irules]
    message.delete(:ssl_profile_client)
    message.delete(:ssl_profile_server)
    message.delete(:http_profile)
    message.delete(:ftp_profile)
    message.delete(:rtsp_profile)
    message.delete(:socks_profile)
    message.delete(:xml_profile)
    message.delete(:stream_profile)
    message.delete(:dns_profile)
    message.delete(:diameter_profile)
    message.delete(:fix_profile)
    message.delete(:request_adapt_profile)
    message.delete(:response_adapt_profile)
    message.delete(:sip_profile)
    message.delete(:statistics_profile)
    message.delete(:request_logging_profile)
    message.delete(:rewrite_profile)
    message.delete(:html_profile)
    message.delete(:oneconnect_profile)
    message.delete(:http_compression_profile)
    message.delete(:web_acceleration_profile)
    message.delete(:spdy_profile)
    message.delete(:ntlm_conn_pool)
    message.delete(:irules)

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
