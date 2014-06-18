require 'puppet/util/network_device/f5'
require 'puppet/util/network_device/f5/transport'
require 'json'

class Puppet::Provider::F5 < Puppet::Provider
  def self.transport
    @transport ||= Puppet::Util::NetworkDevice::F5::Transport.new(Facter.value(:url))
  end

  def self.connection
    transport.connection
  end

  def self.call(url)
    transport.call(url)
  end

  def self.post(url, message)
    transport.post(url, message)
  end

  def self.put(url, message)
    transport.put(url, message)
  end

  def self.delete(url, message)
    transport.delete(url, message)
  end

  def self.find_availability(string)
    transport.find_availability(string)
  end

  def self.find_objects(string)
    transport.find_objects(string)
  end

  def self.integer?(str)
    !!Integer(str)
  rescue ArgumentError, TypeError
    false
  end
end
