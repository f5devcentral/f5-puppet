require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/parameter/f5_name.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_address.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_availability_requirement.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_connection_limit.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_connection_rate_limit.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_description.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_health_monitors.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_ratio.rb'))
require File.expand_path(File.join(File.dirname(__FILE__),'..','..','puppet/property/f5_state.rb'))

Puppet::Type.newtype(:f5_dns) do
  @doc = 'Sets the system DNS on the BIG-IP system'

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

  newproperty(:name_servers, :array_matching => :all) do
    desc "Name Server list. Accepts an array of values."
  end

  newproperty(:search, :array_matching => :all) do
    desc "Domain search list. Accepts an array of values."
  end

end
