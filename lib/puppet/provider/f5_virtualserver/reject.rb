require File.join(File.dirname(__FILE__), '../f5_virtualserver')

Puppet::Type.type(:f5_virtualserver).provide(:reject, parent: Puppet::Provider::F5Virtualserver) do

  has_feature :irules
  has_feature :traffic_class
  has_feature :source_port

  def self.instances
    instances = []
    virtualservers = Puppet::Provider::F5.call_items('/mgmt/tm/ltm/virtual')
    return [] if virtualservers.nil?
    virtualservers = virtualservers.select do |vs|
      vs['reject'] == true
    end

    # empty profile type cache once
    clear_profile_type_cache

    virtualservers.each do |vserver|
      destination_address, destination_port = address_and_port(vserver['destination'])

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
        description:                            vserver["description"],
        destination_address:                    destination_address,
        destination_mask:                       vserver["mask"],
        service_port:                           destination_port,
        #vserver["enabled"]
        vs_score:                               vserver["gtmScore"],
        protocol:                               vserver["ipProtocol"],
        last_hop_pool:                          vserver["lastHopPool"] || "none",
        #vserver["mobileAppTunnel"]
        nat64:                                  vserver["nat64"],
        connection_rate_limit:                  vserver["rateLimit"],
        connection_rate_limit_destination_mask: vserver["rateLimitDstMask"],
        connection_rate_limit_source_mask:      vserver["rateLimitSrcMask"],
        connection_rate_limit_mode:             connection_rate_limit_mode,
        source:                                 vserver["source"],
        source_port:                            source_port,
        #vserver["synCookieStatus"]
        #address_translation:                    vserver["translateAddress"],
        vlan_and_tunnel_traffic:                vlan_and_tunnel_traffic,
        #definition:                             vserver["apiAnonymous"],
        statistics_profile:                     ((applied_profiles["statistics"]||[]).first || {})["fullPath"] || "none",
        irules:                                 vserver["rules"] || "none",
        traffic_class:                          vserver["trafficClasses"],
        #analytics_profile:                      aoeu,
        state:                                  vserver["disabled"] == true ? "disabled" : "enabled",
        reject:                                 true,
      )
    end

    instances
  end

  def message(object)
    super(object.to_hash.merge({:reject => true}))
  end

  mk_resource_methods
end
