require 'puppet/util/network_device/base'
require File.join(File.dirname(__FILE__), '../f5')
require File.join(File.dirname(__FILE__), '../f5/facts')
require File.join(File.dirname(__FILE__), '../transport/f5')

class Puppet::Util::NetworkDevice::F5::Device
  attr_reader :connection
  attr_accessor :url, :transport

  def initialize(url, options = {})
    @autoloader = Puppet::Util::Autoload.new(
      self,
      "puppet/util/network_device/transport"
    )
    autoloader_params = ['f5']
    # As of Puppet 6.0, environment is a required autoloader parameter: (PUP-8696)
    if Gem::Version.new(Puppet.version) >= Gem::Version.new('6.0.0')
      autoloader_params << Puppet.lookup(:current_environment)
    end
    if @autoloader.load(*autoloader_params)
      @transport = Puppet::Util::NetworkDevice::Transport::F5.new(url,options[:debug])
    end
  end

  def facts
    @facts ||= Puppet::Util::NetworkDevice::F5::Facts.new(@transport)

    return @facts.retrieve
  end

end
