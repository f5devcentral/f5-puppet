require 'puppet/parameter/name'
require 'puppet/property/availability'
require 'puppet/property/description'
require 'puppet/property/monitor'

Puppet::Type.newtype(:f5_pool) do
  @doc = 'Manage pool objects'

  apply_to_device
  ensurable

  newparam(:name, :parent => Puppet::Parameter::F5Name, :namevar => true)
  newproperty(:description, :parent => Puppet::Property::F5Description)
  newproperty(:availability, :parent => Puppet::Property::F5Availability)
  newproperty(:monitor, :array_matching => :all, :parent => Puppet::Property::F5Monitor)

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
    options = '<pass-through|mimic|0-255>'
    desc "The IP TOS to the client.
    Valid options: #{options}"

    validate do |value|
      unless value =~ /^(pass-through|mimic)$/ || (value =~ /^\d+$/ && value.to_i.between?(0,255))
        fail ArgumentError, "Valid options: #{options}"
      end
    end
  end

  newproperty(:ip_tos_to_server) do
    options = '<pass-through|mimic|0-255>'
    desc "The IP TOS to the server.
    Valid options: #{options}"

    validate do |value|
      unless value =~ /^(pass-through|mimic)$/ || (value =~ /^\d+$/ && value.to_i.between?(0,255))
        fail ArgumentError, "Valid options: #{options}"
      end
    end
  end

  newproperty(:link_qos_to_client) do
    options = '<pass-through|0-7>'
    desc "The Link TOS to the client.
    Valid options: #{options}"

    validate do |value|
      unless value =~ /^pass-through$/ || (value =~ /^\d+$/ && value.to_i.between?(0,7))
        fail ArgumentError, "Valid options: #{options}"
      end
    end
  end

  newproperty(:link_qos_to_server) do
    options = '<pass-through|0-7>'
    desc "The Link TOS to the server.
    Valid options: #{options}"

    validate do |value|
      unless value =~ /^pass-through$/ || (value =~ /^\d+$/ && value.to_i.between?(0,7))
        fail ArgumentError, "Valid options: #{options}"
      end
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

  newproperty(:ip_encapsulation, :array_matching => :all) do
    encapsulations = %w(gre nvgre dslite ip4ip4 ip4ip6 ip6ip4 ip6ip6 ipip)
    encaps_with_partition = encapsulations.map { |e| "/Partition/#{e} ," }
    desc "The request queue timeout.
    Valid options: <[#{encaps_with_partition}]>"

    validate do |value|
      # We need to check that the value conforms to /Partition/Name, as well
      # as ensuring the Name part is from the above list of encapsulations.
      unless encapsulations.include?(File.basename(value)) && value =~ /^\/\w+\/\w+$/
        fail ArgumentError, "Valid options: <[#{encaps_with_partition}]>"
      end
    end
  end

  newproperty(:load_balancing_method) do
    methods = %w(round-robin ratio-member least-connections-member
    observed-member predictive-member ratio-node least-connection-node
    fastest-node observed-node predictive-node dynamic-ratio-member
    weighted-least-connection-member weighted-least-connection-node
    ratio-session ratio-least-connections-member ratio-least-connection-node)

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

  newproperty(:priority_group_activation) do
    options = '<disabled|Integer>'
    desc "The priority group activation (number of nodes) for the pool.
    Valid options: #{options}"

    validate do |value|
      fail ArgumentError, "Valid options: #{options}" unless value =~ /^(disabled|\d+)$/
    end
  end

  validate do
    if ! self[:monitor] && self[:availability]
      fail ArgumentError, 'ERROR:  Availability cannot be set when no monitor is assigned.'
    end

    # You can't have a minimum of more than the total number of monitors.
    if self[:availability] =~ /\d+/
      if Array(self[:monitor]).count < self[:availability].to_i
        fail ArgumentError, 'ERROR:  Availability count cannot be more than the total number of monitors.'
      end
    end

    if self[:monitor].is_a?(Array) && ! self[:availability]
      fail ArgumentError, 'ERROR:  Availability must be set when monitors are assigned.'
    end
  end

end
