#!/opt/puppetlabs/puppet/bin/ruby

require 'json'
require 'puppet'
require 'puppet/util/network_device/config'
require '../lib/puppet/provider/f5.rb'

# Read input

args = JSON.parse(STDIN.read)
noop = args['_noop'] ? '--noop' : ''
target = args['target'] ? args['target'] : ''

# Initialize variables

save_result = ''
result = {}
exitcode = 0

# Validate the 'target' parameter

if target.empty?
  result[:_error] = {
    msg: 'param error: no target specified',
    kind: 'f5devcentral/f5-puppet',
    details: {
      params: {
        noop: noop,
        target: target
      }
    }
  }
  exitcode = 1
  puts result.to_json
  exit exitcode
end

# Read deviceconfig to identify the device and its url

Puppet.initialize_settings
devices = Puppet::Util::NetworkDevice::Config.devices.dup
devices.select! { |key, _value| key == target }
if devices.empty?
  result[:_error] = {
    msg: "config error: unable to find device in #{Puppet[:deviceconfig]}",
    kind: 'f5devcentral/f5-puppet',
    details: {
      params: {
        noop: noop,
        target: target
      }
    }
  }
  exitcode = 1
  puts result.to_json
  exit exitcode
end

device_url = URI.parse(devices[target].url).to_s

# Validate device url

if device_url.empty?
  result[:_error] = {
    msg: "config error: unable to find url in #{Puppet[:deviceconfig]}",
    kind: 'f5devcentral/f5-puppet',
    details: {
      params: {
        noop: noop,
        target: target
      }
    }
  }
  exitcode = 1
  puts result.to_json
  exit exitcode
end

# Honor the 'noop' parameter

if noop == 'true'
  result['noop'] = {
    msg: 'skipping rest api call of the save command',
    kind: 'f5devcentral/f5-puppet',
    details: {
      params: {
        noop: noop,
        target: target
      }
    }
  }
  puts result.to_json
  exit exitcode
end

# Execute the task

begin
  f5 = Puppet::Util::NetworkDevice::Transport::F5.new(device_url)
  save_result = f5.post('/mgmt/tm/sys/config', { 'command' => 'save' }.to_json)
  unless save_result.status == 200
    error = "http status code: #{save_result.status}"
    # " http response: #{save_result.body}"
    exitcode = 1
  end
rescue => e
  error = e.message
  exitcode = 1
end

# Compose the result

if exitcode.zero?
  result[target] = {
    status: 'success',
    result: 'running configuration saved to startup configuration'
  }
else
  result[:_error] = {
    msg: 'rest api error',
    kind: 'f5devcentral/f5-puppet',
    details: {
      params: {
        noop: noop,
        target: target
      },
      error: error
    }
  }
end

# Return the result

puts result.to_json
exit exitcode
