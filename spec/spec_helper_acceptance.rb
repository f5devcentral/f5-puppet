# Add the fixtures lib dir to RUBYLIB
$:.unshift File.join(File.dirname(__FILE__),  'fixtures', 'lib')

require 'beaker-rspec'
require 'beaker/hypervisor/f5' #from spec/fixtures/lib

def make_site_pp(pp, path = File.join(master['puppetpath'], 'manifests'))
  on master, "mkdir -p #{path}"
  create_remote_file(master, File.join(path, "site.pp"), pp)
  on master, "chown -R #{master['user']}:#{master['group']} #{path}"
  on master, "chmod -R 0755 #{path}"
  on master, "service #{master['puppetservice']} restart"
end

def run_device(options={:allow_changes => true})
  if options[:allow_changes] == false
    acceptable_exit_codes = 0
  else
    acceptable_exit_codes = [0,2]
  end
  on(master, puppet('device', '-v', '--trace','--server',master.to_s), { :acceptable_exit_codes => acceptable_exit_codes })
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

unless ENV['RS_PROVISION'] == 'no' or ENV['BEAKER_provision'] == 'no'
  #install_puppet_from_rpm master, {:release => '7', :family => 'el'}
  install_puppet_from_deb master, {}
  pp=<<-EOS
  $pkg = $::osfamily ? {
    'Debian' => 'puppetmaster',
    'RedHat' => 'puppet-server',
  }
  package { $pkg: ensure => present, }
  -> service { 'puppetmaster': ensure => running, }
  EOS
  apply_manifest(pp)
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
    #puppet_module_install_on(master, {:source => proj_root, :module_name => 'f5'}) #This doesn't seem to work?
    scp_to default, proj_root, "#{default['distmoduledir']}/f5"
    device_conf=<<-EOS
[bigip]
type f5
url https://admin:#{hosts_as('f5').first[:ssh][:password]}@#{hosts_as("f5").first["ip"]}/
EOS
    create_remote_file(master, File.join(master[:puppetpath], "device.conf"), device_conf)
    apply_manifest("include f5")
    on master, puppet('plugin','download','--server',master.to_s)
    on master, puppet('device','-v','--waitforcert','0','--server',master.to_s), {:acceptable_exit_codes => [0,1] }
    on master, puppet('cert','sign','bigip'), {:acceptable_exit_codes => [0,24] }
  end
end
