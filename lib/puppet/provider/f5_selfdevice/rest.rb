require 'puppet/provider/f5'
require 'json'

Puppet::Type.type(:f5_selfdevice).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []

    nodes = Puppet::Provider::F5.call_items('/mgmt/tm/cm/device')
    return [] if nodes.nil?

    nodes.each do |node|
      @@devicename =  node['name']
      instances << new(
      ensure:                   :present,
      name:                     node['fullPath'],
      )
    end

    return instances

  end

  def self.prefetch(resources)
    nodes = instances
    resources.keys.each do |name|
      if provider = nodes.find { |node| node.name == name }
        resources[name].provider = provider
      end
    end
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
    }

    message = strip_nil_values(message)
    message = convert_underscores(message)
    message = rename_keys(map, message)
    message = create_message(basename, message)
    message = string_to_integer(message)

   message = {"command"=>"mv", "name"=>@@devicename}.merge!(message)

  message.to_json
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    result = Puppet::Provider::F5.post("/mgmt/tm/cm/device", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
