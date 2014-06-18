require 'spec_helper'

describe 'description' do

  before :each do
    @node = Puppet::Type.type(:f5_node).new(:name => '/Common/testing')
  end

  it 'should allow description to be set' do
    description = 'Test Description String Here'
    @node[:description] = description
    expect(@node[:description]).to eq(description)
  end

  it 'should fail when description is not a string' do
    expect { @node[:description] = {} }.to raise_error(/must be a String/)
  end
end
