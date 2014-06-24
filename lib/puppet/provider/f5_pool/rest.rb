require 'puppet/provider/f5'
require 'json'

Puppet::Type.type(:f5_pool).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    nodes = Puppet::Provider::F5.call('/mgmt/tm/ltm/pool')
    return [] if nodes.nil?

    nodes.each do |node|
      # Map 0 nodes to disabled.
      node['minActiveMembers'] = 'disabled' if node['minActiveMembers'] == 0

      # We have to munge availability out of the monitor information.
      availability = find_availability(node['monitor']) if node['monitor']

      # Instead of true/false the F5 returns yes/no
      node.each { |_,v| v.gsub!(/^yes$/, 'true') if v.is_a?(String) }
      node.each { |_,v| v.gsub!(/^no$/, 'false') if v.is_a?(String) }

      # Select reject in the GUI, get reset from the REST api.  Who knows!
      node['serviceDownAction'] = 'reject' if node['serviceDownAction'] == 'reset'

      # We only accept true/false for some parameters.
      node['queueOnConnectionLimit'] = :true  if node['queueOnConnectionLimit'] == 'enabled'
      node['queueOnConnectionLimit'] = :false if node['queueOnConnectionLimit'] == 'disabled'
      node['ignorePersistedWeight'] = :true  if node['ignorePersistedWeight'] == 'enabled'
      node['ignorePersistedWeight'] = :false if node['ignorePersistedWeight'] == 'disabled'

      instances << new(
        ensure:                    :present,
        name:                      node['fullPath'],
        availability:              availability,
        description:               node['description'],
        allow_snat:                node['allowSnat'],
        allow_nat:                 node['allowNat'],
        service_down:              node['serviceDownAction'],
        slow_ramp_time:            node['slowRampTime'],
        ip_tos_to_client:          node['ipTosToClient'],
        ip_tos_to_server:          node['ipTosToServer'],
        link_qos_to_client:        node['linkQosToClient'],
        link_qos_to_server:        node['linkQosToServer'],
        reselect_tries:            node['reselectTries'],
        request_queuing:           node['queueOnConnectionLimit'],
        request_queue_depth:       node['queueDepthLimit'],
        request_queue_timeout:     node['queueTimeLimit'],
        ip_encapsulation:          node['profiles'],
        load_balancing_method:     node['loadBalancingMode'],
        priority_group_activation: node['minActiveMembers'],
        ignore_persisted_weight:   node['ignorePersistedWeight'],
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
    hash = object.to_hash

    # Create the message by stripping :present.
    message             = hash.reject { |k, _| [:ensure, :provider].include?(k) }
    message[:name]      = basename
    message[:partition] = partition

    # Apply transformations
    message.each do |k, v|
      message[k] = Integer(v) if Puppet::Provider::F5.integer?(v)
    end
    message[:priority_group_activation] = 0 if hash[:priority_group_activation] == 'disabled'
    message[:allow_nat] = 'yes' if hash[:allow_nat] == :true
    message[:allow_nat] = 'no'  if hash[:allow_nat] == :false
    message[:allow_snat] = 'yes' if hash[:allow_snat] == :true
    message[:allow_snat] = 'no'  if hash[:allow_snat] == :false
    message[:service_down] = 'reject' if hash[:service_down] == 'reject'

    # If monitor is an array then we need to rebuild the message.
    if message[:monitor].is_a?(Array)
      message.reject! { |k, _| [:monitor, :availability].include?(k) }
      message[:monitor] = "min #{hash[:availability]} of #{hash[:monitor].join(' ')}"
    end

    message.to_json
  end

  def flush
    if @property_hash != {}
      result = Puppet::Provider::F5.put("/mgmt/tm/ltm/pool/#{basename}", message(@property_hash))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    Puppet::Provider::F5.post("/mgmt/tm/ltm/pool", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear
  end

  def destroy
    Puppet::Provider::F5.delete("/mgmt/tm/ltm/pool/#{basename}")
    @property_hash.clear
  end

  mk_resource_methods

end
