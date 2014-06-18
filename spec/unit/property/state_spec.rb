require 'spec_helper'

describe 'state' do

  before :each do
    @node = Puppet::Type.type(:f5_node).new(:name => '/Common/testing')
  end

  %w(up, enabled, user-down).each do |state|
    it "should allow state to be set to #{state}" do
      @node[:state] = state
      expect(@node[:state]).to eq(state)
    end
  end

  %w(down, disabled, offline).each do |state|
    it "should fail when state is set to #{state}" do
      expect { @node[:state] = state }.to raise_error(/must be: up|enabled|user-down/)
    end
  end
end
