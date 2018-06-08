require 'puppet/util/feature'
require File.join(File.dirname(__FILE__), '../util/network_device/transport/f5')
require File.join(File.dirname(__FILE__), '../util/network_device/f5/facts')

Puppet.features.add(:f5_device) do
  begin
    transport = nil
    if Puppet::Util::NetworkDevice.current
      #we are in `puppet device`
      transport = Puppet::Util::NetworkDevice.current.transport
    else
      #we are in `puppet resource`
      transport = Puppet::Util::NetworkDevice::Transport::F5.new(Facter.value(:url))
    end
    custom_facts=facts['f5_custom_facts']
    facts     = Puppet::Util::NetworkDevice::F5::Facts.new(transport).retrieve
    unless custom_facts.nil?
      facts=custom_facts.merge(facts)
    end
    if facts and facts[:operatingsystem] == :F5
      true
    else
      false
    end
  rescue
    false
  end
end
