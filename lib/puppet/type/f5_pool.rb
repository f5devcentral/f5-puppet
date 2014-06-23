require 'puppet/parameter/name'
require 'puppet/property/description'

Puppet::Type.newtype(:f5_pool) do
  @doc = 'Manage pool objects'

  apply_to_device
  ensurable

  newparam(:name, :parent => Puppet::Parameter::F5Name, :namevar => true)
  newproperty(:description, :parent => Puppet::Property::F5Description)

  newproperty(:availability) do
    options = '<all|Integer>'
    desc "The number of nodes that must be available for the pool to be up.
    Valid options: #{options}"

    validate do |value|
      unless value =~ /^(all|\d+)$/
        fail ArgumentError, "Valid options: #{options}"
      end
    end
  end

  newproperty(:allow_snat) do
    desc "Allow SNAT?
    Valid options: <true|false>"

    newvalues(:true, :false)
  end

  newproperty(:allow_nat) do
    desc "Allow NAT?
    Valid options: <true|false>"

    newvalues(:true, :false)
  end

  newproperty(:service_down) do
    desc "Action to take when the service is down.
    Valid options: <none|reject|drop|reselect>"

    newvalues('none', 'reject', 'drop', 'reselect')
  end

  newproperty(:slow_ramp_time) do
    options = '<Integer>'
    desc "The slow ramp time for the pool.
    Valid options: #{options}"

    validate do |value|
      fail ArgumentError, "Valid options: #{options}" unless value =~ /^\d+$/
    end
  end

  newproperty(:ip_tos_to_client) do
    options = '<pass|mimic|Integer>'
    desc "The IP TOS to the client.
    Valid options: #{options}"

    validate do |value|
      fail ArgumentError, "Valid options: #{options}" unless value =~ /^(pass|mimic|\d+)$/
    end
  end

  newproperty(:ip_tos_to_server) do
    options = '<pass|mimic|Integer>'
    desc "The IP TOS to the server.
    Valid options: #{options}"

    validate do |value|
      fail ArgumentError, "Valid options: #{options}" unless value =~ /^(pass|mimic|\d+)$/
    end
  end

  newproperty(:link_qos_to_client) do
    options = '<pass|Integer>'
    desc "The Link TOS to the client.
    Valid options: #{options}"

    validate do |value|
      fail ArgumentError, "Valid options: #{options}" unless value =~ /^(pass|\d+)$/
    end
  end

  newproperty(:reselect_tries) do
    options = '<Integer>'
    desc "The number of reselect tries to attempt.
    Valid options: #{options}"

    validate do |value|
      fail ArgumentError, "Valid options: #{options}" unless value =~ /^\d+$/
    end
  end

  newproperty(:request_queuing) do
    desc "Request Queuing?
    Valid options: <true|false>"

    newvalues(:true, :false)
  end

  newproperty(:request_queue_depth) do
    options = '<Integer>'
    desc "The request queue depth.
    Valid options: #{options}"

    validate do |value|
      fail ArgumentError, "Valid options: #{options}" unless value =~ /^\d+$/
    end
  end

  newproperty(:request_queue_timeout) do
    options = '<Integer>'
    desc "The request queue timeout.
    Valid options: #{options}"

    validate do |value|
      fail ArgumentError, "Valid options: #{options}" unless value =~ /^\d+$/
    end
  end

  newproperty(:ip_encapsulation) do
    encapsulations = %w(gre nvgre dslite ip4ip4 ip4ip6 ip6ip4 ip6ip6 ipip)
    desc "The request queue timeout.
    Valid options: <#{encapsulations.join('|')}>"

    validate do |value|
      fail ArgumentError, "Valid options: #{encapsulations.join('|')}" unless encapsulations.include?(value)
    end
  end

  newproperty(:load_balancing_method) do
    methods = %w(round_robin ratio_member least_connections_member
    observed_member predictive_member ratio_node least_connection_node
    fastest_node observed_node predictive_node dynamic_ratio_member
    weighted_least_connection_member weighted_least_connection_node
    ratio_session ratio_least_connections_member ratio_least_connection_node)

    desc "The request queue timeout.
    Valid options: <#{methods.join('|')}>"

    validate do |value|
      fail ArgumentError, "Valid options: <#{methods.join('|')}>" unless methods.include?(value)
    end
  end

  newproperty(:ignore_persisted_weight) do
    desc "Ignore persisted weight?
    Valid options: <true|false>"

    newvalues(:true, :false)
  end
end
