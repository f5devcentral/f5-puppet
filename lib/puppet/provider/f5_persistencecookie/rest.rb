require 'puppet/provider/f5'
require 'json'

Puppet::Type.type(:f5_persistencecookie).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    cookies = Puppet::Provider::F5.call_items('/mgmt/tm/ltm/persistence/cookie')
    return [] if cookies.nil?

    cookies.each do |cookie|
      full_path_uri = cookie['fullPath'].gsub('/','~')

      instances << new(
        ensure:                   :present,
        name:                     cookie['fullPath'],
        description:              cookie['description'],
        method:                   cookie['method'],
        cookie_name:              cookie['cookieName'],
        httponly:                 cookie['httponly'],
        secure:                   cookie['secure'],
        always_send:              cookie['alwaysSend'],
        expiration:               cookie['expiration'],
        cookie_encryption:        cookie['cookieEncryption'],
      )
    end

    instances
  end

  def self.prefetch(resources)
    cookies = instances
    resources.keys.each do |name|
      if provider = cookies.find { |cookie| cookie.name == name }
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
      :'always-send'          => :alwaysSend,
      :'cookie-encryption'    => :cookieEncryption,
      :'cookie-name'          => :cookieName,
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
      result = Puppet::Provider::F5.put("/mgmt/tm/ltm/persistence/cookie/#{full_path_uri}", message(resource))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    result = Puppet::Provider::F5.post("/mgmt/tm/ltm/persistence/cookie", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    full_path_uri = resource[:name].gsub('/','~')
    result = Puppet::Provider::F5.delete("/mgmt/tm/ltm/persistence/cookie/#{full_path_uri}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
