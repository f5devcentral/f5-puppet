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
    if @autoloader.load("f5")
      @transport = Puppet::Util::NetworkDevice::Transport::F5.new(url,options[:debug])
    end
  end

  def facts
    custom_facts=Facter.to_hash['f5_custom_facts']

    Puppet.debug _("###### '%{facts}'") % { facts: custom_facts.to_json }
    @facts ||= Puppet::Util::NetworkDevice::F5::Facts.new(@transport)

    facts=@facts.retrieve

    unless custom_facts.nil?
      facts=custom_facts.merge(facts)
    end

    facts
  end

end
