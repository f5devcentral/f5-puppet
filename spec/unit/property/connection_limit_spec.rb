require 'spec_helper'

describe 'connection_limit' do

  before :each do
    @node = Puppet::Type.type(:f5_node).new(:name => '/Common/testing')
  end

  %w(1 20 300 400 5000).each do |connection_limit|
    it "should allow connection_limit to be set to #{connection_limit}" do
      @node[:connection_limit] = connection_limit
      expect(@node[:connection_limit]).to eq(connection_limit)
    end
  end

  %w(yes please magic present superenabled).each do |connection_limit|
    it "should fail when connection_limit is set to #{connection_limit}" do
      expect { @node[:connection_limit] = connection_limit }.to raise_error()
    end
  end
end
