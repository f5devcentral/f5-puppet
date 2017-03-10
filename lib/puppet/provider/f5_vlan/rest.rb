require_relative('../f5')
require 'json'

Puppet::Type.type(:f5_vlan).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    vlans = Puppet::Provider::F5.call_items('/mgmt/tm/net/vlan')
    return [] if vlans.nil?

    vlans.each do |vlan|
      full_path_uri = vlan['fullPath'].gsub('/','~')

      interfaces = Puppet::Provider::F5.call_items("/mgmt/tm/net/vlan/#{full_path_uri}/interfaces")
      interfaces.each do |interface|
        interface.select! {|k,v| ["name", "tagged"].include?(k) }
        if not interface['tagged']
          interface['tagged'] = false
        end
      end

      instances << new(
        ensure:                   :present,
        name:                     vlan['fullPath'],
        description:              vlan['description'],
        vlan_tag:                 vlan['tag'],
        source_check:             vlan['sourceChecking'],
        mtu:                      vlan['mtu'],
        fail_safe:                vlan['failsafe'],
        fail_safe_timeout:        vlan['failsafeTimeout'],
        fail_safe_action:         vlan['failsafeAction'],
        auto_last_hop:            vlan['autoLasthop'],
        cmp_hash:                 vlan['cmpHash'],
        dag_round_robin:          vlan['dagRoundRobin'],
        sflow_polling_interval:   vlan['sflow']['pollInterval'],
        sflow_sampling_rate:      vlan['sflow']['samplingRate'],
        interfaces:               interfaces,
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

  def create_message(basename, hash)
    # Create the message by stripping :present.
    new_hash            = hash.reject { |k, _| [:ensure, :provider, Puppet::Type.metaparams].flatten.include?(k) }
    new_hash[:name]     = basename

    return new_hash
  end

  def gen_sflow(message)
    if message[:'sflow-polling-interval'] or message[:'sflow-sampling-rate']
      message[:sflow] = {}
    end

    if message[:'sflow-polling-interval']
      message[:sflow][:pollInterval] = message[:'sflow-polling-interval']
    end

    if message[:'sflow-sampling-rate']
      message[:sflow][:samplingRate] = message[:'sflow-sampling-rate']
    end
    
    new_hash = message.reject { |k, _| [:'sflow-polling-interval', :'sflow-sampling-rate'].flatten.include?(k) }

    return new_hash
  end

  def message(object)
    # Allows us to pass in resources and get all the attributes out
    # in the form of a hash.
    message = object.to_hash

    # Map for conversion in the message.
    map = {
      :'vlan-tag'          => :tag,
      :'source-check'      => :sourceChecking,
      :'fail-safe'         => :failsafe,
      :'fail-safe-timeout' => :failsafeTimeout,
      :'fail-safe-action'  => :failsafeAction,
      :'auto-last-hop'     => :autoLasthop,
      :'cmp-hash'          => :cmpHash,
      :'dag-round-robin'   => :dagRoundRobin,
    }

    message = strip_nil_values(message)
    message = convert_underscores(message)
    message = gen_sflow(message)
    message = create_message(basename, message)
    message = rename_keys(map, message)
    message = string_to_integer(message)

    message.to_json
  end

  def flush
    if @property_hash != {}
      full_path_uri = resource[:name].gsub('/','~')
      result = Puppet::Provider::F5.put("/mgmt/tm/net/vlan/#{full_path_uri}", message(resource))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    result = Puppet::Provider::F5.post("/mgmt/tm/net/vlan", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    full_path_uri = resource[:name].gsub('/','~')
    result = Puppet::Provider::F5.delete("/mgmt/tm/net/vlan/#{full_path_uri}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
