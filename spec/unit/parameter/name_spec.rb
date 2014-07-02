require 'spec_helper'

describe 'name' do
  it 'should accept a valid name' do
    Puppet::Type.type(:f5_node).new(:name => '/Common/test')
  end

  it 'should accept a valid name as ipaddress' do
    Puppet::Type.type(:f5_node).new(:name => '/Common/192.168.1.1')
  end

  it 'should fail if name doesnt have a partition' do
    expect{ Puppet::Type.type(:f5_node).new(:name => 'test') }.to raise_error(/name must match the pattern \/Partition\/name/)
  end

  it 'should fail if name isnt a string' do
    expect{ Puppet::Type.type(:f5_pool).new(:name => {}) }.to raise_error(/name must be a String/)
  end

  it 'should require a name' do
    expect{ Puppet::Type.type(:f5_pool).new(:state => 'up') }.to raise_error(/Title or name must be provided/)
  end
end
