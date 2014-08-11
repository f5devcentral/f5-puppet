require 'puppet/util/network_device/f5'
require 'puppet/util/network_device/f5/transport'
require 'json'

class Puppet::Provider::F5 < Puppet::Provider
  def self.transport
    @transport ||= Puppet::Util::NetworkDevice::F5::Transport.new(Facter.value(:url))
  end

  def self.connection
    transport.connection
  end

  def self.call(url)
    transport.call(url)
  end

  def self.post(url, message)
    transport.post(url, message)
  end

  def self.put(url, message)
    transport.put(url, message)
  end

  def self.delete(url)
    transport.delete(url)
  end

  def self.find_availability(string)
    transport.find_availability(string)
  end

  def self.find_objects(string)
    transport.find_objects(string)
  end

  def self.integer?(str)
    !!Integer(str)
  rescue ArgumentError, TypeError
    false
  end

  # This allows us to simply rename keys from the puppet representation
  # to the F5 representation.
  def rename_keys(keys_to_rename, rename_hash)
    keys_to_rename.each do |k, v|
      next unless rename_hash[k]
      value = rename_hash[k]
      rename_hash.delete(k)
      rename_hash[v] = value
    end
    return rename_hash
  end

  def create_message(basename, partition, hash)
    # Create the message by stripping :present.
    new_hash            = hash.reject { |k, _| [:ensure, :loglevel, :provider].include?(k) }
    new_hash[:name]      = basename
    new_hash[:partition] = partition

    return new_hash
  end

  def string_to_integer(hash)
    # Apply transformations
    hash.each do |k, v|
      hash[k] = Integer(v) if self.class.integer?(v)
    end
  end

  def monitor_conversion(hash)
    message = hash
    # If monitor is an array then we need to rebuild the message.
    if hash[:monitor].is_a?(Array)
      message = hash.reject { |k, _| [:monitor, :availability].include?(k) }
      message[:monitor] = "min #{hash[:availability]} of #{hash[:monitor].join(' ')}"
    end

    return message
  end

  def destination_conversion(message)
    if message[:'alias-address'] and message[:'alias-service-port']
      message[:destination] = "#{message[:'alias-address']}:#{message[:'alias-service-port']}"
    elsif message[:'alias-address']
      message[:destination] = message[:'alias-address']
    end
    message.delete(:'alias-address')
    message.delete(:'alias-service-port')

    return message
  end

  # We need to convert our puppet array into a \n seperated string.
  def headers_conversion(message)
    if message[:headers]
      message[:headers] = message[:headers].join("\n")
    end

    return message
  end

  # We need to convert our puppet array into a space seperated string.
  def filters_conversion(message)
    if message[:filter]
      message[:filter] = message[:filter].join(' ')
    end
    if message[:filterNeg]
      message[:filterNeg] = message[:filterNeg].join(' ')
    end

    return message
  end

  def convert_underscores(hash)
    # Here lies some evil magic.  We want to replace all _'s with -'s in the
    # key names of the hash we create from the object we've passed into message.
    #
    # We do this by passing in an object along with .each, giving us an empty
    # hash to then build up with the fixed names.
    hash.each_with_object({}) do |(k ,v), obj|
      key = k.to_s.gsub(/_/, '-').to_sym
      obj[key] = v
    end
  end

  def strip_elements(hash, elements_to_strip)
    message = hash.reject { |k, _| elements_to_strip.include?(k) }

    return message
  end

  # For some reason the object we pass in has undefined parameters in the
  # object with nil values.  Not at all helpful for us.
  def strip_nil_values(hash)
    hash.reject { |k, v| v.nil? }
  end

end
