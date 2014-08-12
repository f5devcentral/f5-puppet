require 'spec_helper'

describe Puppet::Type.type(:f5_irule) do

  before :each do
    @node = Puppet::Type.type(:f5_irule).new(:name => '/Common/testing')
  end

  describe 'verify_signature' do
    %w(yes no disabled enabled true false).each do |value|
      it "should allow verify_signature to be set to #{value}" do
        @node[:verify_signature] = value
        expect(@node[:verify_signature]).to match(/(true|false)/)
      end
    end

    %w(please magic present superenabled).each do |value|
      it "should fail when verify_signature is set to #{value}" do
        expect { @node[:verify_signature] = value }.to raise_error()
      end
    end
  end

  describe 'definition' do
    it "should allow definition to be set to anything" do
      @node[:definition] = 'an arbitrary string'
      expect(@node[:definition]).to eq('an arbitrary string')
    end
  end

  describe 'global validation' do
    it "should succeed when definition is set with signature and verify_signature is true" do
      expect { Puppet::Type.type(:f5_irule).new(
          :name             => '/Common/testing',
          :definition       => "an arbitrary string\ndefinition-signature goes here",
          :verify_signature => true)
      }.to_not raise_error()
    end
    it "should fail when definition is set without signature but verify_signature is true" do
      expect { Puppet::Type.type(:f5_irule).new(
          :name             => '/Common/testing',
          :definition       => "an arbitrary string",
          :verify_signature => true)
      }.to raise_error(/definition does not contain a signature/)
    end
  end
end
