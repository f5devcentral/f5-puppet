require 'spec_helper'

describe Puppet::Type.type(:f5_node) do

  before :each do
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

  describe 'monitor' do
    %w(default none /Common/value).each do |monitor|
      it "should allow monitor to be set to #{monitor}" do
        @node[:monitor] = monitor
        expect(@node[:monitor]).to eq([monitor])
      end
    end

    %w(yes please magic present superenabled).each do |monitor|
      it "should fail when monitor is set to #{monitor}" do
        expect { @node[:monitor] = monitor }.to raise_error()
      end
    end
  end

  describe 'availability' do
    %w(all 1 20 300 400 5000).each do |availability|
      it "should allow availability to be set to #{availability}" do
        @node[:availability] = availability
        expect(@node[:availability]).to eq(availability)
      end
    end

    %w(yes please magic present superenabled).each do |availability|
      it "should fail when availability is set to #{availability}" do
        expect { @node[:availability] = availability }.to raise_error()
      end
    end
  end

  describe 'global validation' do
    it 'should fail if monitor is an array and no availability set' do
      expect { Puppet::Type.type(:f5_node).new(
          :name    => '/Common/testing',
          :monitor => ['/Common/monitor'])
      }.to raise_error(/Availability must be set when monitors are assigned./)
    end

    it 'should fail if monitor is a string and availability set' do
      expect { Puppet::Type.type(:f5_node).new(
          :name         => '/Common/testing',
          :availability => '2',)
      }.to raise_error(/Availability cannot be set when no monitor is assigned./)
    end
  end
end
