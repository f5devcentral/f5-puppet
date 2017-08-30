require 'puppet/provider/f5'
require 'json'

Puppet::Type.type(:f5_device).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    devices = Puppet::Provider::F5.call_items('/mgmt/tm/cm/device')
    return [] if devices.nil?

    devices.each do |device|
      full_path_uri = device['fullPath'].gsub('/','~')

      instances << new(
        ensure:                   :present,
        name:                     device['fullPath'],
        description:              device['description'],
        configsync_ip:            device['configsyncIp'],
        mirror_ip:                device['mirrorIp'],
      )
    end

    instances
  end

  def self.prefetch(resources)
    devices = instances
    resources.keys.each do |name|
      if provider = devices.find { |device| device.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create_message(basename, hash)
    # Create the message by stripping :present.
    new_hash            = hash.reject { |k, _| [:ensure, :name, :provider, Puppet::Type.metaparams].flatten.include?(k) }
  #  new_hash[:name]     = basename

    return new_hash
  end

  def message(object)
    # Allows us to pass in resources and get all the attributes out
    # in the form of a hash.
    message = object.to_hash

    # Map for conversion in the message.
    map = {
      :'configsync-ip'          => :configsyncIp,
      :'mirror-ip'              => :mirrorIp,
    }

    message = strip_nil_values(message)
    message = convert_underscores(message)
    message = rename_keys(map, message)
    message = create_message(basename, message)
    message = string_to_integer(message)

  message.to_json
  end

  def flush
    if @property_hash != {}
      # You can only pass address to create, not modifications.
      flush_message = @property_hash.reject { |k, _| k == :address }
      full_path_uri = resource[:name].gsub('/','~')
      result = Puppet::Provider::F5.put("/mgmt/tm/cm/device/#{full_path_uri}", message(flush_message))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
    return true

  end

  def create
    result = Puppet::Provider::F5.post("/mgmt/tm/cm/device", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    result = Puppet::Provider::F5.delete("/mgmt/tm/cm/device/#{full_path_uri}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
