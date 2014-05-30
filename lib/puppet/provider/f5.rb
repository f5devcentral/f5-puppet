require 'puppet/util/network_device/f5'
require 'json'

class Puppet::Provider::F5 < Puppet::Provider


  def self.connection
    @connection ||= Puppet::Util::NetworkDevice::F5::Connection.new(Facter.value(:url))
    @connection.connection
  end

  def self.call(url)
    result = connection.get("#{url}/?expandSubcollections=true")
    output = JSON.parse(result.body)
    # Return only the items for now.
    output["items"]
  rescue JSON::ParserError
    return nil
  end

  # Given a string containing objects matching /Partition/Object, return an
  # array of all found objects.
  def self.find_objects(string)
    string.scan(/(\/\S+)/).flatten
  end

  # Monitoring:  Parse out the availability integer.
  def self.find_availability(string)
    value = 'all'

    # Look for integers within the string.
    matches = string.match(/min\s(\d+)/)
    if matches
      value = matches[1]
    end

    return value
  end

end
