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

  newproperty(:port_lockdown, :array_matching => :all) do
    desc "Specifies the protocols and services from which this self IP can accept traffic. Note that fewer active protocols enhances the security level of the self IP and its associated VLANs.
Default: Activates only the default protocols and services. You can determine the supported protocols and services by running the tmsh list net self-allow defaults command on the command line.
All: Activates all TCP and UDP services on this self IP.
None / nothing specified: Specifies that this self IP accepts no traffic. If you are using this self IP as the local endpoint for WAN optimization, select this option to avoid potential port conflicts.
Allow Custom: Expands the Custom List option, where you can specify the protocols and services to activate on this self IP."
    #the regex here checks for string:number, to reflect protocol:port, ie udp:0, tcp:80
    newvalues("Default", "All", /\s*:\d+/)

    #this is a comparison that ignores order
    def insync?(is)
      return false unless is.length == @should.length
      return (is.sort == @should.sort or is == @should.map(&:to_s).sort)
    end
  end


  # Autorequire appropriate resources
  autorequire(:f5_vlan) do
    self[:vlan]
  end
end
