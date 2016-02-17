require 'puppet/provider/f5_virtualserver'

Puppet::Type.type(:f5_virtualserver).provide(:standard, parent: Puppet::Provider::F5Virtualserver) do

  has_feature :irules
  has_feature :default_pool
  has_feature :connection_limit
  has_feature :fallback_persistence
  has_feature :persistence
  has_feature :connection_mirroring
  has_feature :protocol_client
  has_feature :protocol_server
  has_feature :standard_profiles
  has_feature :source_translation
  has_feature :address_translation
  has_feature :bandwidth_control
  has_feature :traffic_class
  has_feature :source_port
  has_feature :clone_pool
  has_feature :port_translation
  has_feature :policies

  def self.instances
    instances = []
    virtualservers = Puppet::Provider::F5.call_items('/mgmt/tm/ltm/virtual')
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
        source_address_translation = 'none'
      end

      case vserver["sourcePort"]
      when 'preserve-strict'
        source_port = :preserve_strict
      else
        source_port = vserver["sourcePort"]
      end
      ssl_profile_client = (applied_profiles["client-ssl"]||[]).collect { |x| x["fullPath"] }
      ssl_profile_server = (applied_profiles["server-ssl"]||[]).collect { |x| x["fullPath"] }

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
        fallback_persistence_profile:           vserver["fallbackPersistence"] || "none",
        vs_score:                               vserver["gtmScore"],
        protocol:                               vserver["ipProtocol"] == "any" ? "all" : vserver["ipProtocol"],
        last_hop_pool:                          vserver["lastHopPool"] || "none",
        connection_mirroring:                   vserver["mirror"],
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
        default_persistence_profile:            default_persistence_profile || "none",
        definition:                             vserver["apiAnonymous"],
        protocol_profile_client:                protocol_profile_client || "none",
        protocol_profile_server:                protocol_profile_server || "none",
        authentication_profiles:                vserver["auth"] || ["none"],
        ssl_profile_client:                     ssl_profile_client.empty? ? ["none"] : ssl_profile_client,
        ssl_profile_server:                     ssl_profile_server.empty? ? ["none"] : ssl_profile_server,
        http_profile:                           ((applied_profiles["http"            ]||[]).first || {})["fullPath"] || "none",
        ftp_profile:                            ((applied_profiles["ftp "            ]||[]).first || {})["fullPath"] || "none",
        rtsp_profile:                           ((applied_profiles["rtsp"            ]||[]).first || {})["fullPath"] || "none",
        socks_profile:                          ((applied_profiles["socks"           ]||[]).first || {})["fullPath"] || "none",
        xml_profile:                            ((applied_profiles["xml"             ]||[]).first || {})["fullPath"] || "none",
        stream_profile:                         ((applied_profiles["stream"          ]||[]).first || {})["fullPath"] || "none",
        dns_profile:                            ((applied_profiles["dns"             ]||[]).first || {})["fullPath"] || "none",
        diameter_profile:                       ((applied_profiles["diameter"        ]||[]).first || {})["fullPath"] || "none",
        fix_profile:                            ((applied_profiles["fix"             ]||[]).first || {})["fullPath"] || "none",
        request_adapt_profile:                  ((applied_profiles["request-adapt"   ]||[]).first || {})["fullPath"] || "none",
        response_adapt_profile:                 ((applied_profiles["response-adapt"  ]||[]).first || {})["fullPath"] || "none",
        sip_profile:                            ((applied_profiles["sip"             ]||[]).first || {})["fullPath"] || "none",
        statistics_profile:                     ((applied_profiles["statistics"      ]||[]).first || {})["fullPath"] || "none",
        request_logging_profile:                ((applied_profiles["request-log"     ]||[]).first || {})["fullPath"] || "none",
        rewrite_profile:                        ((applied_profiles["rewrite"         ]||[]).first || {})["fullPath"] || "none",
        html_profile:                           ((applied_profiles["html"            ]||[]).first || {})["fullPath"] || "none",
        oneconnect_profile:                     ((applied_profiles["one-connect"     ]||[]).first || {})["fullPath"] || "none",
        http_compression_profile:               ((applied_profiles["http-compression"]||[]).first || {})["fullPath"] || "none",
        web_acceleration_profile:               ((applied_profiles["web-acceleration"]||[]).first || {})["fullPath"] || "none",
        spdy_profile:                           ((applied_profiles["spdy"            ]||[]).first || {})["fullPath"] || "none",
        ipother_profile:                        ((applied_profiles["ipother"         ]||[]).first || {})["fullPath"] || "none",
        ntlm_conn_pool:                         ((applied_profiles["ntlm"            ]||[]).first || {})["fullPath"] || "none",
        irules:                                 vserver["rules"] || ["none"],
        #analytics_profile:                      aoeu,
        bandwidth_controller:                   vserver["bwcPolicy"],
        traffic_class:                          vserver["trafficClasses"],
        rate_class:                             vserver["rateClass"] || "none",
        policies:                               (vserver["policiesReference"]["items"]||[]).collect { |x| x["fullPath"] },
        default_pool:                           vserver["pool"] || "none",
        state:                                  vserver["disabled"] == true ? "disabled" : "enabled",
      )
    end

    instances
  end

  mk_resource_methods
end
