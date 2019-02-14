require File.join(File.dirname(__FILE__), '../f5')
require 'json'

Puppet::Type.type(:f5_user).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    users = Puppet::Provider::F5.call_items('/mgmt/tm/auth/user')
    return [] if users.nil?

    users.each do |user|

      instances << new(
        ensure:                   :present,
        name:                     user['fullPath'],
        description:              user['description'],
        password:                 user['password'],
      )
    end

    instances
  end

  def self.prefetch(resources)
    users = instances
    resources.keys.each do |name|
      if provider = users.find { |user| user.name == name }
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
      result = Puppet::Provider::F5.put("/mgmt/tm/auth/user/#{basename}", message(resource))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    result = Puppet::Provider::F5.post("/mgmt/tm/auth/user", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    result = Puppet::Provider::F5.delete("/mgmt/tm/auth/user/#{basename}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
