require File.join(File.dirname(__FILE__), '../f5')
require 'json'

Puppet::Type.type(:f5_datagroupexternal).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    dgroups = Puppet::Provider::F5.call_items('/mgmt/tm/ltm/data-group/external')
    return [] if dgroups.nil?

    dgroups.each do |dgroup|
      full_path_uri = dgroup['fullPath'].gsub('/','~')

    instances << new(
      ensure:                   :present,
      name:                     dgroup['fullPath'],
      external_file_name:       dgroup['externalFileName'],
    )
    end

    instances
  end

  def self.prefetch(resources)
    dgroups = instances
    resources.keys.each do |name|
      if provider = dgroups.find { |dgroup| dgroup.name == name }
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
      :'external-file-name'          => :externalFileName,
    }

    message = strip_nil_values(message)
    message = convert_underscores(message)
    message = create_message(basename, message)
    message = rename_keys(map, message)
    message = string_to_integer(message)

    message.to_json
  end

  def flush
    if @property_hash != {}
      full_path_uri = resource[:name].gsub('/','~')

      #modify  the message by stripping :type
      message = message(resource)
      message = JSON.parse(message)
      message.reject! {|k| k == "type"}
      message = message.to_json

      result = Puppet::Provider::F5.put("/mgmt/tm/ltm/data-group/external/#{full_path_uri}", message)
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    result = Puppet::Provider::F5.post("/mgmt/tm/ltm/data-group/external", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    full_path_uri = resource[:name].gsub('/','~')
    result = Puppet::Provider::F5.delete("/mgmt/tm/ltm/data-group/external/#{full_path_uri}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
