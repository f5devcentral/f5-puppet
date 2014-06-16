require 'spec_helper'

describe Puppet::Type.type(:f5_node).provider(:rest) do
  let(:connection) do
    Faraday::Connection.new(:url => 'https://admin:admin@bigip', :ssl => {:verify => false})
  end
  let(:resource) { Puppet::Type.type(:f5_node).new(
    { :name                  => '/Common/test',
      :ensure                => :present,
      :state                 => 'up',
      :description           => 'test node',
      :logging               => 'disabled',
      :monitor               => ['/Common/gateway_icmp', '/Common/icmp'],
      :availability          => '1',
      :ratio                 => '1',
      :connection_limit      => '2',
      :connection_rate_limit => '3',
      :provider              => described_class.name,
    }
  )}
  let(:provider) { resource.provider }
  let(:instance) do
    #resources = [resource]
    #provider.class.stubs(:instances).returns(resources)
    provider.class.instances.first
  end

  describe 'instances' do
    it 'gets a response from the api' do
      response = nil
      VCR.use_cassette('f5_node/main') do
        response = connection.get('/mgmt/tm/ltm/node')
      end
      expect(response.body).not_to be_empty
    end
  end

  describe 'name' do
    it 'returns successfully' do
      require 'pry'
      binding.pry
      expect(instance.name).to eq('/Common/test')
    end
  end

  describe 'state' do
    it 'returns successfully' do
      expect(instance.state).to eq('up')
    end
  end

  describe 'description' do
    it 'returns successfully' do
      expect(resource.description).to eq('test node')
    end
  end

  describe 'logging' do
    it 'returns successfully' do
      expect(resource.logging).to eq('disabled')
    end
  end

end
