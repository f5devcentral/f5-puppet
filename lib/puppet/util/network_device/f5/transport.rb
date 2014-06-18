require 'faraday'
require 'puppet/util/network_device/f5'

class Puppet::Util::NetworkDevice::F5::Transport
  attr_reader :connection

  def initialize(url, _options = {})
    @connection = Faraday.new(url: url, ssl: { verify: false })
  end

  def call(url)
    result = connection.get("#{url}/?expandSubcollections=true")
    output = JSON.parse(result.body)
    # Return only the items for now.
    output['items']
  rescue JSON::ParserError
    return nil
  end

  def post(url, json)
    if valid_json?(json)
      connection.post do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.body = json
      end
    else
      fail('Invalid JSON detected.')
    end
  end

  def put(url, json)
    if valid_json?(json)
      connection.put do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.body = json
      end
    else
      fail('Invalid JSON detected.')
    end
  end

  def delete(url, json)
    if valid_json?(json)
      connection.delete do |req|
        req.url url
        req.headers['Content-Type'] = 'application/json'
        req.body = json
      end
    else
      fail('Invalid JSON detected.')
    end
  end

  def valid_json?(json)
    JSON.parse(json)
    return true
  rescue
    return false
  end

  # Given a string containing objects matching /Partition/Object, return an
  # array of all found objects.
  def find_objects(string)
    string.scan(/(\/\S+)/).flatten
  end

  # Monitoring:  Parse out the availability integer.
  def find_availability(string)
    # Look for integers within the string.
    matches = string.match(/min\s(\d+)/)
    matches[1] if matches
  end
end
