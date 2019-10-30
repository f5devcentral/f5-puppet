require File.join(File.dirname(__FILE__), '../f5')
require 'json'

Puppet::Type.type(:f5_profileclientssl).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    profiles = Puppet::Provider::F5.call_items('/mgmt/tm/ltm/profile/client-ssl')
    return [] if profiles.nil?

    profiles.each do |profile|
      full_path_uri = profile['fullPath'].gsub('/','~')

      instances << new(
        ensure:                      :present,
        name:                        profile['fullPath'],
        description:                 profile['description'],
        cert:                        profile['cert'],
        key:                         profile['key'],
        chain:                       profile['chain']
        proxy_ssl:                   profile['proxySsl'],
        proxy_ssl_passthrough:       profile['proxySslPassthrough'],
        ssl_forward_proxy:           profile['sslForwardProxy'],
        ssl_forward_proxy_bypass:    profile['sslForwardProxyBypass'],
        peer_cert_mode:              profile['peerCertMode'],
        authenticate:                profile['authenticate'],
        retain_certificate:          profile['retainCertificate'],
        authenticate_depth:          profile['authenticateDepth'],
        partition:                   profile['partition'],
      )
    end

    instances
  end

  def self.prefetch(resources)
    profiles = instances
    resources.keys.each do |name|
      if provider = profiles.find { |profile| profile.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create_message(basename, partition, hash)
    # Create the message by stripping :present.
    new_hash            = hash.reject { |k, _| [:ensure, :provider, Puppet::Type.metaparams].flatten.include?(k) }
    new_hash[:name]     = basename
    new_hash[:partition]= partition

    return new_hash
  end

  def message(object)
    # Allows us to pass in resources and get all the attributes out
    # in the form of a hash.
    message = object.to_hash

    # Map for conversion in the message.
    map = {
      :'proxy-ssl'               => :proxySsl,
      :'proxy-ssl-passthrough'               => :proxySslPassthrough,
      :'peer-cert-mode'          => :peerCertMode,
      :'expire-cert-response_control'          => :expireCertResponseControl,
      :'untrusted-cert-response-control'          => :untrustedCertResponseControl,
      :'retain-certificate'          => :retainCertificate,
      :'authenticate-depth'          => :authenticateDepth,
    }

    message = strip_nil_values(message)
    message = convert_underscores(message)
    message = create_message(basename, partition, message)
    message = rename_keys(map, message)
    message = string_to_integer(message)

    message.to_json
  end

  def flush
    if @property_hash != {}
      full_path_uri = resource[:name].gsub('/','~')
      result = Puppet::Provider::F5.put("/mgmt/tm/ltm/profile/client-ssl/#{full_path_uri}", message(resource))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    result = Puppet::Provider::F5.post("/mgmt/tm/ltm/profile/client-ssl", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    full_path_uri = resource[:name].gsub('/','~')
    result = Puppet::Provider::F5.delete("/mgmt/tm/ltm/profile/client-ssl/#{full_path_uri}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
