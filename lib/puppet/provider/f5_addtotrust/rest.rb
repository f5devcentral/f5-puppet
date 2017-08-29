require 'puppet/provider/f5'
require 'json'

Puppet::Type.type(:f5_addtotrust).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []

    nodes = Puppet::Provider::F5.call_items('/mgmt/tm/cm/trust-domain')
    return [] #if nodes.nil?

  end

  def self.prefetch(resources)
    nodes = instances
  end

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
      :'device-name'            => :deviceName,
    }

    message = strip_nil_values(message)
    message = convert_underscores(message)
    message = rename_keys(map, message)
    message = create_message(basename, message)
    message = string_to_integer(message)

   message1 = {"command"=>"run", "name"=>"Root", "caDevice"=>true}
   message = message1.merge!(message)

  message.to_json
  end

  def flush
    if @property_hash != {}
      # You can only pass address to create, not modifications.
      flush_message = @property_hash.reject { |k, _| k == :address }
      result = Puppet::Provider::F5.put("/mgmt/tm/sys/ntp/", message(flush_message))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
    # return true as NTP reource always exists
#    return false
  end

  def create
    result = Puppet::Provider::F5.post("/mgmt/tm/cm/add-to-trust", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    result = Puppet::Provider::F5.delete("/mgmt/tm/sys/ntp")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
