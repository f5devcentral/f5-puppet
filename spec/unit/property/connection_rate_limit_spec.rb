require 'spec_helper'

describe 'connection_rate_limit' do

  before :each do
    @node = Puppet::Type.type(:f5_node).new(:name => '/Common/testing')
  end

  [1,20,300,400,5000].each do |connection_rate_limit|
    it "should allow connection_rate_limit to be set to #{connection_rate_limit}" do
      @node[:connection_rate_limit] = connection_rate_limit.to_s
      expect(@node[:connection_rate_limit]).to eq(connection_rate_limit)
    end
  end

  %w(yes please magic present superenabled).each do |connection_rate_limit|
    it "should fail when connection_rate_limit is set to #{connection_rate_limit}" do
      expect { @node[:connection_rate_limit] = connection_rate_limit }.to raise_error()
    end
  end
end
