require 'spec_helper'

describe Puppet::Type.type(:f5_node) do

  before :each do
    #allow(Facter).to receive(:value).with(:url).and_return('https://admin:admin@bigip')
    #allow(Facter).to receive(:value).with(:feature)
    @node = Puppet::Type.type(:f5_node).new(:name => '/Common/testing')
  end

  describe 'name' do
    it 'should return name' do
      expect(@node[:name]).to eq('/Common/testing')
    end

    it 'should fail if name isnt a string' do
      expect{ Puppet::Type.type(:f5_node).new(:name => {}) }.to raise_error(/name must be a String/)
    end

    it 'should require a name' do
      expect{ Puppet::Type.type(:f5_node).new(:state => 'up') }.to raise_error(/Title or name must be provided/)
    end
  end

  describe 'state' do
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

  describe 'description' do
    it 'should allow description to be set' do
      description = 'Test Description String Here'
      @node[:description] = description
      expect(@node[:description]).to eq(description)
    end

    it 'should fail when description is not a string' do
      expect { @node[:description] = {} }.to raise_error(/must be a String/)
    end
  end

  describe 'logging' do
    %w(disabled enabled true false).each do |logging|
      it "should allow logging to be set to #{logging}" do
        @node[:logging] = logging
        expect(@node[:logging]).to eq(logging.to_sym)
      end
    end

    %w(yes please magic present superenabled).each do |logging|
      it "should fail when logging is set to #{logging}" do
        expect { @node[:logging] = logging }.to raise_error()
      end
    end
  end

end
