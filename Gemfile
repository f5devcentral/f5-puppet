source ENV['GEM_SOURCE'] || "https://rubygems.org"

group :development, :unit_tests do
  gem 'puppet-blacksmith', '>= 3.4.0', :require => false
  gem 'rake',                          :require => false
  gem 'rspec-puppet',                  :require => false
  gem 'puppetlabs_spec_helper',        :require => false
  gem 'puppet-lint',                   :require => false
  gem 'pry',                           :require => false
  gem 'parallel_tests', '< 2.10.0',    :require => false if Gem::Version.new(RUBY_VERSION.dup) < Gem::Version.new('2.0.0')
  gem 'parallel_tests',                :require => false if Gem::Version.new(RUBY_VERSION.dup) >= Gem::Version.new('2.0.0')
end

group :system_tests do
  gem 'beaker-rspec',                 :require => false
  gem 'beaker',                       :require => false
  gem 'beaker-pe',                    :require => false
  gem 'beaker-puppet_install_helper', :require => false
  gem 'serverspec'
  gem 'rbnacl'
  gem 'rbnacl-libsodium'
  gem 'bcrypt_pbkdf'
end

if facterversion = ENV['FACTER_GEM_VERSION']
  gem 'facter', facterversion, :require => false
else
  gem 'facter', :require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

# vim:ft=ruby
