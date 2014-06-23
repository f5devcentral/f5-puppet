require 'puppet/provider/f5'
require 'json'

Puppet::Type.type(:f5_pool).provide(:rest, parent: Puppet::Provider::F5) do

  def self.instances
    instances = []
    nodes = Puppet::Provider::F5.call('/mgmt/tm/ltm/pool')
    nodes.each do |node|
      # Things just don't appear in the results if unset.
      node['minActiveMembers'] == 'disabled' unless node['minActiveMembers']
      availability = find_availability(node['monitor']) if node['monitor']

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

    # Map for conversion in the message.
    map = {
      connection_limit: :connectionLimit,
      connection_rate_limit: :rateLimit
    }

    # Create the message by stripping :present.
    message             = hash.reject { |k, _| [:ensure, :loglevel, :provider].include?(k) }
    message[:name]      = basename
    message[:partition] = partition

    # We need to rename some properties back to the API.
    map.each do |k, v|
      next unless hash[k]
      value = hash[k]
      message.delete(k)
      message[v] = value
    end

    # Apply transformations
    message.each do |k, v|
      message[k] = Integer(v) if Puppet::Provider::F5.integer?(v)
    end

    # If monitor is an array then we need to rebuild the message.
    if message[:monitor].is_a?(Array)
      message.reject! { |k, _| [:monitor, :availability].include?(k) }
      message[:monitor] = "min #{hash[:availability]} of #{hash[:monitor].join(' ')}"
    end

    message.to_json
  end

  def flush
    if @property_hash != {}
      # You can only pass address to create, not modifications.
      flush_message = @property_hash.reject { |k, _| k == :address }
      result = Puppet::Provider::F5.put("/mgmt/tm/ltm/node/#{basename}", message(flush_message))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    Puppet::Provider::F5.post("/mgmt/tm/ltm/node", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear
  end

  def destroy
    Puppet::Provider::F5.delete("/mgmt/tm/ltm/node/#{basename}")
    @property_hash.clear
  end

  mk_resource_methods

end
