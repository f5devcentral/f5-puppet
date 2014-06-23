require 'spec_helper'

describe 'address' do

  before :each do
    @node = Puppet::Type.type(:f5_node).new(:name => '/Common/testing')
  end

  %w(10.1.1.1 192.168.1.1 4.2.2.2).each do |address|
    it "should allow address to be set to #{address}" do
      @node[:address] = address
      expect(@node[:address]).to eq(address)
    end
  end

  [ '2001:cdba:0000:0000:0000:0000:3257:9652',
    '2001:cdba:0:0:0:0:3257:9652',
    '2001:cdba::3257:9652' ].each do |address|
    it "should allow address to be set to #{address}" do
      @node[:address] = address
      expect(@node[:address]).to eq(address)
    end
  end

  %w(yes please magic present superenabled).each do |address|
    it "should fail when address is set to #{address}" do
      expect { @node[:address] = address }.to raise_error()
    end
  end
end
