require 'puppet/parameter/f5_name'
require 'puppet/property/f5_description'
require 'puppet/property/f5_truthy'

Puppet::Type.newtype(:f5_selfip) do
  @doc = 'A self IP address is an IP address on the BIG-IP system that you associate with a VLAN, to access hosts in that VLAN. By virtue of its netmask, a self IP address represents an address space, that is, a range of IP addresses spanning the hosts in the VLAN, rather than a single host address. You can associate self IP addresses not only with VLANs, but also with VLAN groups.'

  apply_to_device
  ensurable

  newparam(:name, :parent => Puppet::Parameter::F5Name, :namevar => true)

  newparam(:address) do
    desc "Specify either an IPv4 or an IPv6 address. For an IPv4 address, you must specify a /32 IP address per RFC 3021. and " 
  end

  newproperty(:vlan) do
    desc "Specifies the VLAN associated with this self IP address."
  end

  newproperty(:traffic_group) do
    desc "Specifies the traffic group to associate with the self IP. You can click the box to have the self IP inherit the traffic group from the root folder, or clear the box to select a specific traffic group for the self IP."
  end

  newproperty(:inherit_traffic_group) do
    desc "Inherit traffic group from current partition / path"
    newvalues(:true, :false)
  end

  # Autorequire appropriate resources
  autorequire(:f5_vlan) do
    self[:vlan]
  end
end
