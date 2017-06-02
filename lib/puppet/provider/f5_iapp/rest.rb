require File.join(File.dirname(__FILE__), '../f5')
require 'json'

Puppet::Type.type(:f5_iapp).provide(:rest, parent: Puppet::Provider::F5) do

  def initialize(value={})
    super(value)
    @create_elements = false
  end

  def self.instances
    instances = []
    iapps = Puppet::Provider::F5.call_items('/mgmt/tm/sys/application/service')
    return [] if iapps.nil?

    iapps.each do |iapp|
      variables = iapp['variables'].inject({}) do |memo,hash|
        memo[hash['name']] = hash['value']
        memo
      end

      tables = iapp['tables'].inject({}) do |memo,table|
        key = table['name']
        columns = table['columnNames']
        value = (table['rows']||[]).collect do |hash|
          hash['row'].each_with_index.inject({}) do |m,(cell,i)|
            m[columns[i]] = cell
            m
          end
        end
        memo[key] = value
        memo
      end
      instances << new(
        name:      iapp['fullPath'],
        ensure:    :present,
        template:  iapp['template'],
        variables: variables,
        tables:    tables,
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
    }

    message[:variables] = message[:variables].collect do |k,v|
      {
        'name'      => k,
        'encrypted' => 'no',
        'value'     => v,
      }
    end
    message[:tables] = message[:tables].collect do |k,v|
      tables = {}
      tables["name"] = k
      tables["columnNames"] = []
      tables["rows"] = []
      v.each do |row|
        tables["columnNames"] = (tables["columnNames"] + row.keys).uniq
      end
      v.each_with_index do |row,i|
        newrow = tables["columnNames"].collect do |name|
          row[name] || ""
        end
        tables["rows"][i] = { "row" => newrow }
      end
      tables
    end
    message[:'execute-action'] = 'definition' unless @create_elements

    message = rename_keys(map, message)
    message = create_message(basename, partition, message)

    message.to_json
  end

  def flush
    if @property_hash != {}
      result = Puppet::Provider::F5.put("/mgmt/tm/sys/application/service/#{api_name}.app~#{basename}", message(@property_hash))
    end
    return result
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def create
    @create_elements = true
    result = Puppet::Provider::F5.post("/mgmt/tm/sys/application/service", message(resource))
    # We clear the hash here to stop flush from triggering.
    @property_hash.clear

    return result
  end

  def destroy
    result = Puppet::Provider::F5.delete("/mgmt/tm/sys/application/service/#{api_name}.app~#{basename}")
    @property_hash.clear

    return result
  end

  mk_resource_methods

end
