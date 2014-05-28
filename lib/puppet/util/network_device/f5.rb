require 'faraday'
require 'puppet/util/network_device'

module Puppet::Util::NetworkDevice::F5
  class Connection

    attr_reader :connection

    def initialize(url)
      @connection = Faraday.new(:url => url, :ssl => {:verify => false})
    end
  end
end
