require 'faraday'
require 'puppet/util/network_device/f5'
require 'puppet/util/network_device/f5/facts'
require 'puppet/util/network_device/f5/transport'

class Puppet::Util::NetworkDevice::F5::Device
  attr_reader :connection

  def initialize(url, options)
    @transport ||= Puppet::Util::NetworkDevice::F5::Transport.new(url, options)
  end

  def facts
    @facts ||= Puppet::Util::NetworkDevice::F5::Facts.new(@transport)

    return @facts.retrieve
  end

end
