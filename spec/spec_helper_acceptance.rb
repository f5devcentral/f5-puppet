require 'beaker-rspec'
require 'beaker/puppet_install_helper'

def wait_for_master(max_retries)
  1.upto(max_retries) do |retries|
    on(master, "curl -skIL https://#{master.hostname}:8140", { :acceptable_exit_codes => [0,1,7] }) do |result|
      return if result.stdout =~ /400 Bad Request/

      counter = 2 ** retries
      logger.debug "Unable to reach Puppet Master, Sleeping #{counter} seconds for retry #{retries}..."
      sleep counter
    end
  end
  raise Exception, "Could not connect to Puppet Master."
end

def device_facts_ok(max_retries)
  1.upto(max_retries) do |retries|
    on master, puppet('device','-v','--user','root','--server',master.to_s), {:acceptable_exit_codes => [0,1] } do |result|
      return if result.stdout =~ %r{Notice: (Finished|Applied) catalog}

      counter = 10 * retries
      logger.debug "Unable to get a successful catalog run, Sleeping #{counter} seconds for retry #{retries}"
      sleep counter
    end
  end
  raise Exception, "Could not get a successful catalog run."
end

def make_site_pp(pp, path = File.join(master['puppetpath'], 'manifests'))
  on master, "mkdir -p #{path}"
  create_remote_file(master, File.join(path, "site.pp"), pp)
  if ENV['PUPPET_INSTALL_TYPE'] == 'foss'
    on master, "chown -R #{master['user']}:#{master['group']} #{path}"
    on master, "chmod -R 0755 #{path}"
    on master, "service #{master['puppetservice']} restart"
    wait_for_master(3)
  end
end

def run_device(options={:allow_changes => true})
  if options[:allow_changes] == false
    acceptable_exit_codes = 0
  else
    acceptable_exit_codes = [0,2]
  end
  on(default, puppet('device','--verbose','--color','false','--user','root','--trace','--server',master.to_s), { :acceptable_exit_codes => acceptable_exit_codes }) do |result|
    if options[:allow_changes] == false
      expect(result.stdout).to_not match(%r{^Notice: /Stage\[main\]})
    end
    expect(result.stderr).to_not match(%r{^Error:})
    expect(result.stderr).to_not match(%r{^Warning:})
  end
end

def run_resource(resource_type, resource_title=nil)
  f5_host = hosts_as('f5').first
  options = {:ENV => {
    'FACTER_url' => "https://admin:#{f5_host[:ssh][:password]}@#{f5_host["ip"]}"
  } }
  if resource_title
    on(master, puppet('resource', resource_type, resource_title, '--trace', options), { :acceptable_exit_codes => 0 }).stdout
  else
    on(master, puppet('resource', resource_type, '--trace', options), { :acceptable_exit_codes => 0 }).stdout
  end
end

def wait_for_api(max_retries)
  1.upto(max_retries) do |retries|
    on(master, "curl -skIL https://admin:#{hosts_as('f5').first[:ssh][:password]}@#{hosts_as('f5').first["ip"]}/mgmt/tm/cm/device", { :acceptable_exit_codes => [0,1] }) do |result|
      return if result.stdout =~ /502 Bad Gateway/

      counter = 10 * retries
      logger.debug "Unable to connect to F5 REST API, retrying in #{counter} seconds..." 
      sleep counter
    end
  end
  raise Exception, "Could not connect to API."
end

unless ENV['RS_PROVISION'] == 'no' or ENV['BEAKER_provision'] == 'no'
  run_puppet_install_helper_on master

  on master, "setenforce 0"
  if ENV['PUPPET_INSTALL_TYPE'] == 'pe'
    pp=<<-EOS
    package { 'puppetserver': ensure => present, }
    -> service { 'puppetserver': ensure => running, }
    EOS
  else
    pp=<<-EOS
    $pkg = $::osfamily ? {
      'Debian' => 'puppetmaster',
      'RedHat' => 'puppet-server',
    }
    package { $pkg: ensure => present, }
    -> service { 'puppetmaster': ensure => running, }
    EOS
  end

  apply_manifest_on(master, pp)
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    copy_module_to(default, :source => proj_root, :module_name => 'f5')
    if ENV['PUPPET_INSTALL_TYPE'] == 'pe'
      on master, puppet('module', 'install', 'puppetlabs-pe_gem')
      on master, '/bin/echo "nodes: 20" > /etc/puppetlabs/license.key'
    end

    device_conf=<<-EOS
[f5-dut]
type f5
url https://admin:#{hosts_as('f5').first[:ssh][:password]}@#{hosts_as("f5").first["ip"]}/
EOS
    create_remote_file(master, File.join(master[:puppetpath], "device.conf"), device_conf)
    apply_manifest("include f5")
    on master, puppet('plugin','download','--server',master.to_s)
    on master, puppet('device','-v','--user','root','--waitforcert','0','--server',master.to_s), {:acceptable_exit_codes => [0,1] }
    on master, puppet('cert','sign','f5-dut'), {:acceptable_exit_codes => [0,24] }

    if ENV['PUPPET_INSTALL_TYPE'] == 'foss'
      on master, "service #{master['puppetservice']} restart"
      #Verify the Puppet Master is ready
      wait_for_master(10)
    end

    #Queries the F5 REST API & Puppet Master until they have been initialized
    wait_for_api(10)
    #Verify Facts can be retreived 
    device_facts_ok(3)
  end
end
