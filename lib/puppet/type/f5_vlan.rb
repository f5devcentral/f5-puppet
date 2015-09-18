require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/parameter/f5_name.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_description.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_truthy.rb'))

Puppet::Type.newtype(:f5_vlan) do
  @doc = 'Manage vlan objects'

  apply_to_device
  ensurable

  newparam(:name) do
    def self.postinit
      @doc ||= "The name of the object.
      Valid options: <String>"
    end

    validate do |value|
      fail ArgumentError, "#{name} must be a String" unless value.is_a?(String)
    end

    isnamevar

  end

  newproperty(:description, :parent => Puppet::Property::F5Description)
        
  newproperty(:vlan_tag) do
    desc "Specifies the VLAN ID. If you do not specify a VLAN ID, the BIG-IP system assigns an ID automatically. Valid range: 1 - 4094."

    munge do |value|
      Integer(value)
    end

    validate do |value|
      fail ArgumentError, "Valid range: 0 - 65535" unless (value =~ /^\d+$/ and Integer(value) >= 1 and Integer(value) <= 4094)
    end

    
  end
        
  newproperty(:source_check, :parent => Puppet::Property::F5truthy) do
    truthy_property("Source Checking. Causes the BIG-IP system to verify that the return path of an initial packet is through the same VLAN from which the packet originated. Valid values are 'enabled' or 'disabled'.")
  end
        
  newproperty(:mtu) do
    desc "MTU. Valid range: 576 - 65535."

    munge do |value|
      Integer(value)
    end

    validate do |value|
      fail ArgumentError, "Valid range: 576 - 65535" unless (value =~ /^\d+$/ and Integer(value) >= 576 and Integer(value) <= 65535)
    end
  end
        
  newproperty(:fail_safe, :parent => Puppet::Property::F5truthy) do
    desc "Triggers fail-over in a redundant system when certain VLAN-related events occur. Valid values are 'enabled' or 'disabled'."
    truthy_property('Fail Safe')
  end
        
  newproperty(:fail_safe_timeout) do
    desc "Fail Safe Timeout. Valid range: 0 - 4294967295."

    munge do |value|
      Integer(value)
    end

    validate do |value|
      fail ArgumentError, "Valid range: 0 - 4294967295" unless (value =~ /^\d+$/ and Integer(value) >= 0 and Integer(value) <= 4294967295)
    end
  end
        
  newproperty(:fail_safe_action) do
    desc "Fail Safe Action. Valid values are 'reboot' or 'restart-all'."
    newvalues(:reboot, :'restart-all')
  end
        
  newproperty(:auto_last_hop) do
    desc "Auto Last Hop. Valid values are 'default', 'enabled' or 'disabled'."
    newvalues(:default, :enabled, :disabled)
  end
        
  newproperty(:cmp_hash) do
    desc "CMP Hash. Valid values are 'default', 'src-ip' or 'dst-ip'."
    newvalues(:default, :'src-ip', :'dst-ip')
  end
        
  newproperty(:dag_round_robin, :parent => Puppet::Property::F5truthy) do
    desc "DAG Round Robin. Valid values are 'enabled' or 'disabled'"
    truthy_property('DAG Round Robin')
  end
        
  newproperty(:sflow_polling_interval) do
    desc "SFLOW Polling Interval (Seconds). Valid range: 0 - 86400."

    munge do |value|
      Integer(value)
    end

    validate do |value|
      fail ArgumentError, "Valid range: 0 - 86400" unless (value =~ /^\d+$/ and Integer(value) >= 0 and Integer(value) <= 86400)
    end
  end
        
  newproperty(:sflow_sampling_rate) do
    desc "SFLOW Sampling Rate (Packets). Valid range: 0 - 102400."

    munge do |value|
      Integer(value)
    end

    validate do |value|
      fail ArgumentError, "Valid range: 0 - 102400" unless (value =~ /^\d+$/ and Integer(value) >= 0 and Integer(value) <= 102400)
    end
  end

  newproperty(:interfaces, :array_matching => :all) do
    desc "Interfaces that this vlan resource is bound to. Correct format example is: [{name => '1.1', tagged => true}, {name => '2.1', tagged => true}]"

    def insync?(is)
      is = [] if is == :absent
      should.sort! { |x, y| x["name"] <=> y["name"] }
      is.sort! { |x, y| x["name"] <=> y["name"] }
      should == is
    end

    validate do |value|
      failure_message = "Invalid interfaces property format. Correct format example is: [{name => '1.1', tagged => true}, {name => '2.1', tagged => true}]"
      fail ArgumentError, failure_message unless value.kind_of?(Hash)
      fail ArgumentError, failure_message if value.empty?
      fail ArgumentError, failure_message unless (value.has_key?('name') and value.has_key?('tagged'))
      value.each do |key, value|
        if not (key == 'name' or key == 'tagged')
          fail ArgumentError, failure_message
        end
      end
    end
  end
end
