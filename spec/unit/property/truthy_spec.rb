require 'spec_helper'

describe 'truthy' do

  before :each do
    @node = Puppet::Type.type(:f5_monitor).new(:name => '/Common/testing')
  end

  %w(yes true enabled).each do |state|
    it "should allow debug to be set to #{state}" do
      @node[:debug] = state
      expect(@node[:debug]).to eq(:yes)
    end
  end

  %w(no false disabled).each do |state|
    it "should allow debug to be set to #{state}" do
      @node[:debug] = state
      expect(@node[:debug]).to eq(:no)
    end
  end

  %w(foo bar enable).each do |state|
    it "should fail when debug is set to #{state}" do
      expect { @node[:debug] = state }.to raise_error(/must be one of: yes, no, true, false, enabled, disabled/)
    end
  end
end
