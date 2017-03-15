require File.join(File.dirname(__FILE__), 'f5')

class Puppet::Provider::F5Virtualserver < Puppet::Provider::F5
  def self.prefetch(resources)
    vservers = instances
    resources.keys.each do |name|
      if provider = vservers.find { |vserver| vserver.name == name }
        resources[name].provider = provider
      end
    end
  end

  def flush
    if @property_hash != {}
      result = Puppet::Provider::F5.put("/mgmt/tm/ltm/virtual/#{api_name}", message(@property_hash))
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
    result = Puppet::Provider::F5.delete("/mgmt/tm/ltm/virtual/#{api_name}")
    @property_hash.clear

    return result
  end

  def message(object)
    # Allows us to pass in resources and get all the attributes out
    # in the form of a hash.
    message = object.to_hash

    # Map for conversion in the message.
    map = {
      :'address-translation'                    => :'translate-address',
      :'authentication-profiles'                => :auth,
      :'auto-last-hop'                          => :'auto-lasthop',
      :'bandwidth-controller'                   => :'bwc-policy',
      :'connection-mirroring'                   => :mirror,
      :'connection-rate-limit'                  => :'rate-limit',
      :'connection-rate-limit-destination-mask' => :'rate-limit-dst-mask',
      :'connection-rate-limit-mode'             => :'rate-limit-mode',
      :'connection-rate-limit-source-mask'      => :'rate-limit-src-mask',
      :'default-persistence-profile'            => :persist,
      :'default-pool'                           => :pool,
      :'destination-mask'                       => :mask,
      :'fallback-persistence-profile'           => :'fallback-persistence',
      :'port-translation'                       => :'translate-port',
      :'traffic-class'                          => :'traffic-classes',
      :'vs-score'                               => :'gtm-score',
      :definition                               => :'api-anonymous',
      :irules                                   => :rules,
      :protocol                                 => :'ip-protocol',
    }

    message = message.reject { |k,v| v.nil? }

    # empty profile type cache once
    self.class.clear_profile_type_cache

    if message[:provider] == :performance_http and self.class.find_profile_type(message[:protocol_profile_client]) != 'fasthttp'
      fail ArgumentError, "Incorrect protocol_profile_client for performance_http provider: Must be a 'fasthttp' protocol profile, got '#{self.class.find_profile_type(message[:protocol_profile_client])}'"
    end
    if message[:provider] == :performance_l4 and self.class.find_profile_type(message[:protocol_profile_client]) != 'fastl4'
      fail ArgumentError, "Incorrect protocol_profile_client for performance_l4 provider: Must be a 'fastl4' protocol profile, got '#{self.class.find_profile_type(message[:protocol_profile_client])}'"
    end

    message[:destination] = "#{message[:destination_address]}:#{message[:service_port]}"
    message.delete(:destination_address)
    message.delete(:service_port)
    message[:default_persistence_profile] = [] if message[:default_persistence_profile] == "none"
    message[:fallback_persistence_profile] = "" if message[:fallback_persistence_profile] == "none"
    message.delete(:authentication_profiles) if message[:authentication_profiles] == ["none"]
    message[:irules] = [] if message[:irules] == ["none"]
    # We want last_hop_pool, default_pool, and perhaps others to stay "none", so don't delete them from message

    if message[:source_address_translation]
      sat = message[:source_address_translation]
      message[:source_address_translation] = Hash.new
      if sat.is_a? String and sat == 'automap'
        message[:source_address_translation]["type"] = sat
      elsif sat.is_a? String and sat == 'none'
        message[:source_address_translation]["type"] = sat
      elsif sat.is_a? Hash
        message[:source_address_translation]["type"] = sat.first[0]
        message[:source_address_translation]["pool"] = sat.first[1]
      end
    end

    # Configure the state
    if message[:state] == "forced_offline" or message[:state] == "disabled"
      message[:disabled] = true
    else
      message[:enabled] = true
    end
    message.delete(:state)

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
    message.delete(:clone_pools) if message[:clone_pools].empty?

    message[:protocol] = :any if message[:protocol] == :all or message[:protocol] == "all"

    message[:profiles] = Array.new
    message.delete(:protocol_profile_client) if message[:protocol_profile_client] == "none"
    message.delete(:protocol_profile_server) if message[:protocol_profile_server] == "none"
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
        if ['fastl4','fasthttp'].include?(self.class.find_profile_type(message[:protocol_profile_client]))
          message[:profiles] << { :name => message[:protocol_profile_client], }
        else
          message[:profiles] << { :name => message[:protocol_profile_client], :context => :clientside, }
        end
        message.delete(:protocol_profile_client)
      end
    end
    message[:profiles] += message[:ssl_profile_client].collect { |p| { :name => p } } if message[:ssl_profile_client] and message[:ssl_profile_client] != ["none"]
    message[:profiles] += message[:ssl_profile_server].collect { |p| { :name => p } } if message[:ssl_profile_server] and message[:ssl_profile_server] != ["none"]
    message[:profiles] << { :name => message[:diameter_profile]         } if message[:diameter_profile]         and message[:diameter_profile]         != "none"
    message[:profiles] << { :name => message[:dns_profile]              } if message[:dns_profile]              and message[:dns_profile]              != "none"
    message[:profiles] << { :name => message[:fix_profile]              } if message[:fix_profile]              and message[:fix_profile]              != "none"
    message[:profiles] << { :name => message[:ftp_profile]              } if message[:ftp_profile]              and message[:fix_profile]              != "none"
    message[:profiles] << { :name => message[:html_profile]             } if message[:html_profile]             and message[:html_profile]             != "none"
    message[:profiles] << { :name => message[:http_compression_profile] } if message[:http_compression_profile] and message[:http_compression_profile] != "none"
    message[:profiles] << { :name => message[:http_profile]             } if message[:http_profile]             and message[:http_profile]             != "none"
    message[:profiles] << { :name => message[:ipother_profile]          } if message[:ipother_profile]          and message[:ipother_profile]          != "none"
    message[:profiles] << { :name => message[:oneconnect_profile]       } if message[:oneconnect_profile]       and message[:oneconnect_profile]       != "none"
    message[:profiles] << { :name => message[:request_adapt_profile]    } if message[:request_adapt_profile]    and message[:request_adapt_profile]    != "none"
    message[:profiles] << { :name => message[:request_logging_profile]  } if message[:request_logging_profile]  and message[:request_logging_profile]  != "none"
    message[:profiles] << { :name => message[:response_adapt_profile]   } if message[:response_adapt_profile]   and message[:response_adapt_profile]   != "none"
    message[:profiles] << { :name => message[:rewrite_profile]          } if message[:rewrite_profile]          and message[:rewrite_profile]          != "none"
    message[:profiles] << { :name => message[:rtsp_profile]             } if message[:rtsp_profile]             and message[:rtsp_profile]             != "none"
    message[:profiles] << { :name => message[:sip_profile]              } if message[:sip_profile]              and message[:sip_profile]              != "none"
    message[:profiles] << { :name => message[:socks_profile]            } if message[:socks_profile]            and message[:socks_profile]            != "none"
    message[:profiles] << { :name => message[:spdy_profile]             } if message[:spdy_profile]             and message[:spdy_profile]             != "none"
    message[:profiles] << { :name => message[:statistics_profile]       } if message[:statistics_profile]       and message[:statistics_profile]       != "none"
    message[:profiles] << { :name => message[:stream_profile]           } if message[:stream_profile]           and message[:stream_profile]           != "none"
    message[:profiles] << { :name => message[:web_acceleration_profile] } if message[:web_acceleration_profile] and message[:web_acceleration_profile] != "none"
    message[:profiles] << { :name => message[:xml_profile]              } if message[:xml_profile]              and message[:xml_profile]              != "none"
    message[:profiles] << { :name => message[:ntlm_conn_pool]           } if message[:ntlm_conn_pool]           and message[:ntlm_conn_pool]           != "none"
    message.delete(:ssl_profile_client)
    message.delete(:ssl_profile_server)
    message.delete(:diameter_profile)
    message.delete(:dns_profile)
    message.delete(:fix_profile)
    message.delete(:ftp_profile)
    message.delete(:html_profile)
    message.delete(:http_compression_profile)
    message.delete(:http_profile)
    message.delete(:ipother_profile)
    message.delete(:ntlm_conn_pool)
    message.delete(:oneconnect_profile)
    message.delete(:request_adapt_profile)
    message.delete(:request_logging_profile)
    message.delete(:response_adapt_profile)
    message.delete(:rewrite_profile)
    message.delete(:rtsp_profile)
    message.delete(:sip_profile)
    message.delete(:socks_profile)
    message.delete(:spdy_profile)
    message.delete(:statistics_profile)
    message.delete(:stream_profile)
    message.delete(:web_acceleration_profile)
    message.delete(:xml_profile)

    message[:source_port] = 'preserve-strict' if message[:source_port] == :preserve_strict

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
    message = strip_nil_values(message)
    message = convert_underscores(message)
    message = rename_keys(map, message)
    message = string_to_integer(message)

    message = create_message(basename, partition, message)

    message.to_json
  end
end
