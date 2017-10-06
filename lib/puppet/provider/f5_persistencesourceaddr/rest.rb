require 'puppet/provider/f5'
require 'json'

Puppet::Type.type(:f5_persistencesourceaddr).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    addresses = Puppet::Provider::F5.call_items('/mgmt/tm/ltm/persistence/source-addr')
    return [] if addresses.nil?

    addresses.each do |address|
      full_path_uri = address['fullPath'].gsub('/','~')

      instances << new(
        ensure:                    :present,
        name:                      address['fullPath'],
        description:               address['description'],
        match_across_pools:        address['matchAcrossPools'],
        match_across_services:     address['matchAcrossServices'],
        match_across_virtuals:     address['matchAcrossVirtuals'],
        hash_algorithm:            address['hashAlgorithm'],
        mask:                      address['mask'],
        timeout:                   address['timeout'],
        override_connection_limit: address['overrideConnectionLimit'],
      )
    end

    instances
  end

  def self.prefetch(resources)
    addresses = instances
    resources.keys.each do |name|
      if provider = addresses.find { |address| address.name == name }
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
      :'hash-algorithm'              => :hashAlgorithm,
      :'override-connection-limit'   => :overrideConnectionLimit,
    }

    message = strip_nil_values(message)
    message = convert_underscores(message)
    #message = gen_sflow(message)
    message = create_message(basename, message)
    message = rename_keys(map, message)
    message = string_to_integer(message)

    message.to_json
  end

  def flush
    if @property_hash != {}
      full_path_uri = resource[:name].gsub('/','~')
      result = Puppet::Provider::F5.put("/mgmt/tm/ltm/persistence/source-addr/#{full_path_uri}", message(resource))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    result = Puppet::Provider::F5.post("/mgmt/tm/ltm/persistence/source-addr", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    full_path_uri = resource[:name].gsub('/','~')
    result = Puppet::Provider::F5.delete("/mgmt/tm/ltm/persistence/source-addr/#{full_path_uri}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
