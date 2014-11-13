require 'puppet/util/feature'
require 'puppet/util/network_device/f5/transport'
require 'puppet/util/network_device/f5/facts'

Puppet.features.add(:f5_device) do
  begin
    transport = Puppet::Util::NetworkDevice::F5::Transport.new(Facter.value(:url))
    facts     = Puppet::Util::NetworkDevice::F5::Facts.new(transport).retrieve
    if facts and facts[:operatingsystem] == :F5
      true
    else
      false
    end
  rescue
    false
  end
end
