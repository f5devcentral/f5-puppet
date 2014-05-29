require 'rubygems'
require 'rspec/mocks'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'faraday'
require 'vcr'

VCR.configure do |c|
  c.default_cassette_options = { :serialize_with => :syck }
  c.cassette_library_dir = 'spec/fixtures/vcr'
  c.hook_into :faraday
end

RSpec.configure do |config|
  config.mock_with :rspec
end
