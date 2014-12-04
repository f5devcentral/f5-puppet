require 'puppet/provider/f5'
require 'json'

Puppet::Type.type(:f5_monitor).provide(:tcp, parent: Puppet::Provider::F5) do

  has_feature :strings
  has_feature :reverse
  has_feature :transparent
  has_feature :dscp

  def initialize(value={})
    super(value)
    @create_elements = false
  end

  def self.instances
    instances = []
    monitors = Puppet::Provider::F5.call('/mgmt/tm/ltm/monitor/tcp')
    return [] if monitors.nil?

    monitors.each do |monitor|
      aliasAddress, aliasServicePort = monitor['destination'].split(':')
      instances << new(
        ensure:                 :present,
        alias_address:          aliasAddress,
        alias_service_port:     aliasServicePort,
        parent_monitor:         monitor['defaultsFrom'] || 'none',
        description:            monitor['description'],
        interval:               monitor['interval'],
        manual_resume:          monitor['manualResume'],
        name:                   monitor['fullPath'],
        time_until_up:          monitor['timeUntilUp'],
        timeout:                monitor['timeout'],
        transparent:            monitor['transparent'],
        up_interval:            monitor['upInterval'],
        send_string:            monitor['send'] || "",
        receive_disable_string: monitor['recvDisable'] || "",
        receive_string:         monitor['recv'] || "",
        reverse:                monitor['reverse'],
        ip_dscp:                monitor['ipDscp'],
      )
    end

    instances
  end

  def self.prefetch(resources)
    nodes = instances
    resources.keys.each do |name|
      if provider = nodes.find { |node| node.name == name }
        resources[name].provider = provider
      end
    end
  end

  def basename
    File.basename(resource[:name])
  end

  def partition
    File.dirname(resource[:name])
  end

  def message(object)
    # Allows us to pass in resources and get all the attributes out
    # in the form of a hash.
    message = object.to_hash

    # Map for conversion in the message.
    map = {
      :'send-string'            => :send,
      :'receive-string'         => :recv,
      :'receive-disable-string' => :recvDisable,
      :'parent-monitor'         => :defaultsFrom,
    }

    message.delete(:parent_monitor) if message[:parent_monitor] == "none"

    message = convert_underscores(message)
    message = rename_keys(map, message)
    message = create_message(basename, partition, message)
    message = string_to_integer(message)
    message = destination_conversion(message)
    elements_to_strip = [:'alias-address', :'alias-service-port']
    message = strip_elements(message, elements_to_strip)

    message.to_json
  end

  def flush
    if @property_hash != {}
      result = Puppet::Provider::F5.put("/mgmt/tm/ltm/monitor/tcp/#{basename}", message(@property_hash))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @create_elements = true
    result = Puppet::Provider::F5.post("/mgmt/tm/ltm/monitor/tcp", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    result = Puppet::Provider::F5.delete("/mgmt/tm/ltm/monitor/tcp/#{basename}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

  def parent_monitor=(value)
    fail ArgumentError, "ERROR: Attempting to change `parent_monitor` from '#{self.provider.parent_monitor}' to '#{self[:parent_monitor]}'; cannot be modified after a monitor has been created."
  end
end
