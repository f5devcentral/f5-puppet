source ENV['GEM_SOURCE'] || "https://rubygems.org"

group :development, :unit_tests do
  gem 'rake',                    :require => false
  gem 'rspec-puppet',            :require => false
  gem 'puppetlabs_spec_helper',  :require => false
  gem 'puppet-lint',             :require => false
  gem 'pry',                     :require => false
end

group :system_tests do
  gem 'beaker-rspec',     :require => false

  # We pin this to what is currently the latest version of Beaker. We know
  # that our overriding in spec/fixtures/beaker/hypervisor/f5.rb work with
  # this version of Beaker. Our channges need to be merged into Beaker and
  # afterwards we can remove or custom hypervisor and unpin our version or
  # Beaker (or at least allow it to slide).
  gem 'beaker', '2.25.0', :require => false
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
