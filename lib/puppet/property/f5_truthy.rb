require 'puppet/property'

class Puppet::Property::F5truthy < Puppet::Property
  def self.truthy_property(desc=nil, trueval=:enabled, falseval=:disabled)
    options = [:yes, :no, :true, :false, :enabled, :disabled]
    desc "#{desc or "Undocumented attribute."}
    Valid options: <#{options.join("|")}>"

    validate do |value|
      unless options.include?(value.to_s.to_sym)
        raise ArgumentError, "#{name} must be one of: #{options.join(", ")}."
      end
    end
    munge do |value|
      case value.to_s.to_sym
      when :true, :enabled, :yes
        trueval
      when :false, :disabled, :no
        falseval
      end
    end
  end
end
