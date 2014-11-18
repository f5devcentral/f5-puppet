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
    facts = {}
    result = @transport.call('/mgmt/tm/cm/device').first

      #'group_id',
      #'pva_version',
      #'uptime',
    [ :baseMac,
      :chassisId,
      :fullPath,
      :hostname,
      :managementIp,
      :marketingName,
      :partition,
      :platformId,
      :timeZone,
      :version
    ].each do |fact|
      facts[fact] = result[fact.to_s]
    end

    # Map F5 names to expected standard names.
    facts[:fqdn]            = facts[:hostname]
    facts[:macaddress]      = facts[:baseMac]
    facts[:operatingsystem] = :F5

    return facts
  end
end
