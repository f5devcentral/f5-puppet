require 'spec_helper'

describe Puppet::Type.type(:f5_pool).provider(:rest) do
  let(:resource) do
    Puppet::Type.type(:f5_pool).new(
      name:                      '/Common/test',
      ensure:                    :present,
      allow_nat:                 'false',
      allow_snat:                'false',
      description:               'test3',
      ignore_persisted_weight:   'true',
      ip_encapsulation:          ['/Common/ip4ip4'],
      ip_tos_to_client:          '244',
      ip_tos_to_server:          '244',
      link_qos_to_client:        '7',
      link_qos_to_server:        'pass-through',
      load_balancing_method:     'ratio-node',
      priority_group_activation: '2',
      request_queue_depth:       '13',
      request_queue_timeout:     '14',
      request_queuing:           'false',
      reselect_tries:            '12',
      service_down:              'drop',
      slow_ramp_time:            '11',
      members:                   [{'connection_limit' => '1', 'enable' => 'enabled', 'name' => '/Common/192.168.1.1', 'port' => '1', 'ratio' => '1'}],
      provider:                  described_class.name)
  end
  let(:provider) { resource.provider }

  before :each do
    allow(Facter).to receive(:value).with(:url).and_return('https://admin:admin@bigip')
    allow(Facter).to receive(:value).with(:feature)
  end

  describe 'instances' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_pool/instances') do
        result = provider.class.instances
      end
      expect(result.count).to eq(3)
    end
  end

  describe 'create' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_pool/create') do
        result = provider.create
      end
      expect(result.status).to eq(200)
    end
  end

  describe 'flush' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_pool/flush') do
        provider.class.prefetch({ '/Common/test' => resource})
        provider.link_qos_to_client= '4'
        result = provider.flush
      end
      expect(result.status).to eq(200)
    end
  end

  describe 'destroy' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_pool/destroy') do
        result = provider.destroy
      end
      expect(result.status).to eq(200)
    end
  end

end
