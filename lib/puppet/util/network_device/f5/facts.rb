class Puppet::Util::NetworkDevice::F5::Facts

  attr_reader :transport

  def initialize(transport)
    @transport = transport
  end

  def retrieve
    facts = {}
    facts.merge(parse_device_facts)
  end

  def parse_device_facts
    facts = {
      'operatingsystem' => 'F5'
    }

    if response = @transport.call('/mgmt/tm/cm/device') and items = response['items']
      result = items.first
    else
      Puppet.warning("Did not receive device details. iControl REST requires Administrator level access.")
      return facts
    end

      #'group_id',
      #'pva_version',
      #'uptime',
    [ 'baseMac',
      'chassisId',
      'failoverState',
      'fullPath',
      'hostname',
      'managementIp',
      'marketingName',
      'partition',
      'platformId',
      'timeZone',
      'version'
    ].each do |fact|
      facts[fact] = result[fact.to_s]
    end

    # Map F5 names to expected standard names.
    facts['fqdn']                   = facts['hostname']
    facts['macaddress']             = facts['baseMac']
    facts['operatingsystemrelease'] = facts['version']
    facts['ipaddress']              = facts['managementIp']
    facts['productname']            = facts['marketingName']

    facts['interfaces'] = 'mgmt'
    facts['ipaddress_mgmt']  = facts['ipaddress']
    facts['macaddress_mgmt'] = facts['macaddress']
    return facts
  end
end
