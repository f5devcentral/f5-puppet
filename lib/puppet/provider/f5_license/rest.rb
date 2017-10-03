require 'puppet/provider/f5'
require 'json'

Puppet::Type.type(:f5_license).provide(:rest, parent: Puppet::Provider::F5) do

  def create_message(basename, hash)
    # Create the message by stripping :present.
    new_hash            = hash.reject { |k, _| [:ensure,:name, :provider, Puppet::Type.metaparams].flatten.include?(k) }

    return new_hash
  end

  def message(object)
    # Allows us to pass in resources and get all the attributes out
    # in the form of a hash.
    message = object.to_hash

    map = {
   :'registration-key'    => :registrationKey,
    }

    message = strip_nil_values(message)
    message = convert_underscores(message)
    message = rename_keys(map, message)
    message = create_message(basename, message)
    message = string_to_integer(message)

    message = {"command"=>"install"}.merge!(message)
  message.to_json
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    result = Puppet::Provider::F5.post("/mgmt/tm/sys/license", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
