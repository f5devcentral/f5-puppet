require 'puppet/util/network_device/f5'
require 'json'

class Puppet::Provider::F5 < Puppet::Provider


  def self.connection
    @connection ||= Puppet::Util::NetworkDevice::F5::Connection.new(Facter.value(:url))
    @connection.connection
  end

  def self.call(url)
    result = connection.get(url)
    output = JSON.parse(result.body)
    # Return only the items for now.
    output["items"]
  rescue JSON::ParserError
    return nil
  end

end
