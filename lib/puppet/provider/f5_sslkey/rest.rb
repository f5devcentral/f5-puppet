require 'puppet/provider/f5'
require 'json'

Puppet::Type.type(:f5_sslkey).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    Puppet.debug('Puppet::Provider::F5::F5_sslkey: Got to self.instances.')
    instances = []
    keys = Puppet::Provider::F5.call_items('/mgmt/tm/sys/crypto/key')
    return [] if keys.nil?

    keys.each do |key|

      instances << new(
        ensure: :present,
        name:   key['fullPath'],
      )

    end

    instances
  end

  def self.prefetch(resources)
    Puppet.debug('Puppet::Provider::F5::F5_sslkey: Got to self.prefetch.')
    resources.keys.each do |name|
      if provider = instances.find { |instance| instance.name == name }
        resources[name].provider = provider
      end
    end
  end

  def message(object)
    # Allows us to pass in resources and get all the attributes out
    # in the form of a hash.
    message = object.to_hash

    # Map for conversion in the message.
    map = {
    }

    message = { "command"=>"install", "name"=> message[:keyname], "from-local-file"=> message[:from_local_file] }
    message.to_json
  end

  def exists?
    Puppet.debug("Puppet::Provider::F5::F5_sslkey: Got to exists?. #{name}")
    @property_hash[:ensure] == :present 
  end

  def create
    Puppet.debug("Puppet::Provider::F5::F5_sslkey: Got to create. #{name}")
    result = Puppet::Provider::F5.post("/mgmt/tm/sys/crypto/key", message(resource))

    return result
  end

  def destroy
    Puppet.debug("Puppet::Provider::F5::F5_sslkey: Got to destroy. #{name}")
    result = Puppet::Provider::F5.delete("/mgmt/tm/sys/crypto/key/#{api_name}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
