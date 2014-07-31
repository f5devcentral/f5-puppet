require 'puppet/provider/f5'
require 'json'

Puppet::Type.type(:f5_monitor).provide(:tcp_half, parent: Puppet::Provider::F5) do

  def initialize(value={})
    super(value)
    @create_elements = false
  end

  def self.instances
    instances = []
    monitors = Puppet::Provider::F5.call('/mgmt/tm/ltm/monitor/tcp-half-open')
    monitors.each do |monitor|
      instances << new(
        ensure:                :present,
        name:                  monitor['fullPath'],
        description:           monitor['description'],
        destination:           monitor['destination'],
        interval:              monitor['interval'],
        up_interval:           monitor['upInterval'],
        time_until_up:         monitor['timeUntilUp'],
        timeout:               monitor['timeout'],
        manual_resume:         monitor['manualResume'],
        transparent:           monitor['transparent'],
        alias_address:         monitor['aliasAddress'],
        alias_service_port:    monitor['aliasServicePort'],
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
    map = {}

    message = convert_underscores(message)
    message = rename_keys(map, message)
    message = create_message(basename, partition, message)
    message = string_to_integer(message)
    message = monitor_conversion(message)
    unless @create_elements
      elements_to_strip = [:'alias-address', :'alias-service-port']
      message = strip_elements(message, elements_to_strip)
    end

    message.to_json
  end

  def flush
    if @property_hash != {}
      # You can only pass address to create, not modifications.
      flush_message = @property_hash.reject { |k, _| k == :address }
      result = Puppet::Provider::F5.put("/mgmt/tm/ltm/monitor/tcp-half-open/#{basename}", message(flush_message))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @create_elements = true
    result = Puppet::Provider::F5.post("/mgmt/tm/ltm/monitor/tcp-half-open", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    result = Puppet::Provider::F5.delete("/mgmt/tm/ltm/monitor/tcp-half-open/#{basename}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
