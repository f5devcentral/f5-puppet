# Add the fixtures lib dir to RUBYLIB
$:.unshift File.join(File.dirname(__FILE__),  'fixtures', 'lib')

require 'beaker-rspec'
require 'beaker/hypervisor/f5' #from spec/fixtures/lib

def wait_for_master(max_retries)
  1.upto(max_retries) do |retries|
    on(master, "curl -kIL https://puppet:8140", { :acceptable_exit_codes => [0,1,7] }) do |result|
      return if result.stdout =~ /400 Bad Request/

      counter = 3 ** retries
      logger.debug "Unable to reach Puppet Master, Sleeping #{counter} seconds for retry #{retries}..."
      sleep counter
    end
  end
  raise Puppet::Error, "Could not connect to Puppet Master."
end

def make_site_pp(pp, path = File.join(master['puppetpath'], 'manifests'))
  on master, "mkdir -p #{path}"
  create_remote_file(master, File.join(path, "site.pp"), pp)
  on master, "chown -R #{master['user']}:#{master['group']} #{path}"
  on master, "chmod -R 0755 #{path}"
  on master, "service #{master['puppetservice']} restart"
  wait_for_master(3)
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
    on(master, "curl -kIL https://admin:#{hosts_as('f5').first[:ssh][:password]}@#{hosts_as('f5').first["ip"]}/tmui/", { :acceptable_exit_codes => [0,1] }) do |result|
      return if result.stdout =~ /302 Found/

      counter = 10 * retries
      logger.debug "Unable to connect to F5 REST API, retrying in #{counter} seconds..." 
      sleep counter
    end
  end
  raise Puppet::Error, "Could not connect to API."
end

unless ENV['RS_PROVISION'] == 'no' or ENV['BEAKER_provision'] == 'no'
  install_puppet_from_rpm master, {:release => '7', :family => 'el'}
  #install_puppet_from_deb master, {}
  pp=<<-EOS
  $pkg = $::osfamily ? {
    'Debian' => 'puppetmaster',
    'RedHat' => 'puppet-server',
  }
  package { $pkg: ensure => present, }
  -> service { 'puppetmaster': ensure => running, }
  EOS
  apply_manifest(pp)
  if master['platform'].match(/^(deb|ubu)/)
    # Why do we still have templatedir in the puppet.conf?
    on master, "sed -i 's/templatedir=.*//' /etc/puppet/puppet.conf"
  end
  #foss_opts = { :default_action => 'gem_install' }
  #install_puppet(foss_opts) #installs on all hosts
  #install_pe #takes forever
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

    #Queries the REST API until it's been initialized
    wait_for_api(10)
  end
end
