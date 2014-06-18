require 'spec_helper'

describe 'ratio' do

  before :each do
    @node = Puppet::Type.type(:f5_node).new(:name => '/Common/testing')
  end

  %w(1 20 300 400 5000).each do |ratio|
    it "should allow ratio to be set to #{ratio}" do
      @node[:ratio] = ratio
      expect(@node[:ratio]).to eq(ratio)
    end
  end

  %w(yes please magic present superenabled).each do |ratio|
    it "should fail when ratio is set to #{ratio}" do
      expect { @node[:ratio] = ratio }.to raise_error()
    end
  end
end
