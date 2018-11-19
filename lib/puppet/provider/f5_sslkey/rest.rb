require File.join(File.dirname(__FILE__), '../f5')
require 'json'

Puppet::Type.type(:f5_sslkey).provide(:rest, parent: Puppet::Provider::F5) do

  def create_message(basename, hash)
    # Create the message by stripping :present.
    new_hash            = hash.reject { |k, _| [:ensure,:name, :provider, Puppet::Type.metaparams].flatten.include?(k) }
  #  new_hash[:name]     = basename

    return new_hash
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
     false
  end

  def create
    result = Puppet::Provider::F5.post("/mgmt/tm/sys/crypto/key", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
