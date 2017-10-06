require 'puppet/provider/f5'
require 'json'

Puppet::Type.type(:f5_persistencessl).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    ssls = Puppet::Provider::F5.call_items('/mgmt/tm/ltm/persistence/ssl')
    return [] if ssls.nil?

    ssls.each do |ssl|
      full_path_uri = ssl['fullPath'].gsub('/','~')

      instances << new(
        ensure:                   :present,
        name:                     ssl['fullPath'],
        description:              ssl['description'],
        mirror:                   ssl['mirror'],
        match_across_pools:       ssl['matchAcrossPools'],
        match_across_services:    ssl['matchAcrossServices'],
        match_across_virtuals:    ssl['matchAcrossVirtuals'],
        timeout:                  ssl['timeout'],
        override_connection_limit: ssl['overrideConnectionLimit'],
      )
    end

    instances
  end

  def self.prefetch(resources)
    ssls = instances
    resources.keys.each do |name|
      if provider = ssls.find { |ssl| ssl.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create_message(basename, hash)
    # Create the message by stripping :present.
    new_hash            = hash.reject { |k, _| [:ensure, :provider, Puppet::Type.metaparams].flatten.include?(k) }
    new_hash[:name]     = basename

    return new_hash
  end


  def message(object)
    # Allows us to pass in resources and get all the attributes out
    # in the form of a hash.
    message = object.to_hash

    # Map for conversion in the message.
    map = {
      :'match-across-pools'          => :matchAcrossPools,
      :'match-across-services'       => :matchAcrossServices,
      :'match-across-virtuals'       => :matchAcrossVirtuals,
      :'override-connection-limit'   => :overrideConnectionLimit,
    }

    message = strip_nil_values(message)
    message = convert_underscores(message)
    #message = gen_sflow(message)
    message = create_message(basename, message)
    message = rename_keys(map, message)
    message = string_to_integer(message)

puts message
    message.to_json
  end

  def flush
    if @property_hash != {}
      full_path_uri = resource[:name].gsub('/','~')
      result = Puppet::Provider::F5.put("/mgmt/tm/ltm/persistence/ssl/#{full_path_uri}", message(resource))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    result = Puppet::Provider::F5.post("/mgmt/tm/ltm/persistence/ssl", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    full_path_uri = resource[:name].gsub('/','~')
    result = Puppet::Provider::F5.delete("/mgmt/tm/ltm/persistence/ssl/#{full_path_uri}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
