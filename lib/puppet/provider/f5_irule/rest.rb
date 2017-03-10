require_relative('../f5')
require 'json'

Puppet::Type.type(:f5_irule).provide(:rest, parent: Puppet::Provider::F5) do

  def initialize(value={})
    super(value)
    @create_elements = false
  end

  def self.instances
    instances = []
    irules = Puppet::Provider::F5.call_items('/mgmt/tm/ltm/rule')
    return [] if irules.nil?

    irules.each do |irule|
      if irule['apiRawValues'] and irule['apiRawValues']['verificationStatus'] == 'signature-verified'
        verify = :true
      elsif irule['ignoreVerification'] == 'true'
        verify = :false
      end

      instances << new(
        name:             irule['fullPath'],
        ensure:           :present,
        definition:       irule['apiAnonymous'],
        verify_signature: verify,
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

  def message(object)
    # Allows us to pass in resources and get all the attributes out
    # in the form of a hash.
    message = object.to_hash

    # Map for conversion in the message.
    map = {
      :definition => :apiAnonymous
    }

    if message[:verify_signature] == :true
      message[:ignoreVerification] = 'false'
      message[:apiRawValues] = { 'verificationStatus' => 'signature-verified' }
    elsif message[:verify_signature] == :false
      message[:ignoreVerification] = 'true'
      message[:apiRawValues] = { 'verificationStatus' => 'signature-not-verified' }
    end
    message.delete(:verify_signature)
    message = rename_keys(map, message)
    message = create_message(basename, partition, message)

    message.to_json
  end

  def flush
    if @property_hash != {}
      result = Puppet::Provider::F5.put("/mgmt/tm/ltm/rule/#{api_name}", message(@property_hash))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @create_elements = true
    result = Puppet::Provider::F5.post("/mgmt/tm/ltm/rule", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    result = Puppet::Provider::F5.delete("/mgmt/tm/ltm/rule/#{api_name}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
