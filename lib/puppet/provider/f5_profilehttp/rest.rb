require 'puppet/provider/f5'
require 'json'

Puppet::Type.type(:f5_profilehttp).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    profiles = Puppet::Provider::F5.call_items('/mgmt/tm/ltm/profile/http')
    return [] if profiles.nil?

    profiles.each do |profile|
      full_path_uri = profile['fullPath'].gsub('/','~')

      instances << new(
          ensure: :present,
          name: profile['fullPath'],
          description: profile['description'],
          fallback_host: profile['fallbackHost'],
          fallback_status_codes: profile['fallbackStatusCodes'],
          defaults_from: profile['defaultsFrom'],
          encrypt_cookies: profile['encryptCookies'],
          encrypt_cookie_secret: profile['encryptCookieSecret'],
          hsts_mode: profile['hsts']['mode'],
          hsts_maximum_age:profile['hsts']['maximumAge'],
          hsts_preload:profile['hsts']['preload'],
          hsts_include_subdomains:profile['hsts']['includeSubdomains'],
      )
    end

    instances
  end

  def self.prefetch(resources)
    profiles = instances
    resources.keys.each do |name|
      if provider = profiles.find {|profile| profile.name == name}
        resources[name].provider = provider
      end
    end
  end

  def create_message(basename, partition, hash)
    # Create the message by stripping :present.
    new_hash = hash.reject {|k, _| [:ensure, :provider, Puppet::Type.metaparams].flatten.include?(k)}
    new_hash[:name] = basename
    new_hash[:partition] = partition

    return new_hash
  end


  def message(object)
    # Allows us to pass in resources and get all the attributes out
    # in the form of a hash.
    message = object.to_hash

    # Map for conversion in the message.
    map = {
        :'fallback-host' => :fallbackHost,
        :'fallback-status-codes' => :fallbackStatusCodes,
        :'encrypt-cookies' => :encryptCookies,
        :'encrypt-cookie-secret' => :encryptCookieSecret,
        :'defaults-from' => :defaultsFrom,
    }

    message = strip_nil_values(message)
    message = convert_hsts(message)
    message = convert_underscores(message)
    message = create_message(basename, partition, message)
    message = rename_keys(map, message)
    message = string_to_integer(message)

    message.to_json
  end

  def convert_hsts(hash)
    hash[:hsts] =
        rename_keys(
            {
                :hsts_maximum_age => 'maximum-age',
                :hsts_include_subdomains => 'include-subdomains',
                :hsts_mode => 'mode',
                :hsts_preload => 'preload',
            },
            strip_nil_values(hash.select {|key, value| key.to_s.start_with?('hsts_')}))
    hash.reject {|key, value| key.to_s.start_with?('hsts_')}
  end

  def flush
    if @property_hash != {}
      full_path_uri = resource[:name].gsub('/','~')
      result = Puppet::Provider::F5.patch("/mgmt/tm/ltm/profile/http/#{full_path_uri}", message(resource))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    result = Puppet::Provider::F5.post("/mgmt/tm/ltm/profile/http", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    full_path_uri = resource[:name].gsub('/','~')
    result = Puppet::Provider::F5.delete("/mgmt/tm/ltm/profile/http/#{full_path_uri}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
