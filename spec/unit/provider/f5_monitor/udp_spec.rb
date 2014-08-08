require 'spec_helper'

describe Puppet::Type.type(:f5_monitor).provider(:udp) do
  let(:resource) do
    Puppet::Type.type(:f5_monitor).new(
      name:                   '/Common/udp_test',
      ensure:                 :present,
      description:            'udptest',
      alias_address:          '10.0.0.1',
      alias_service_port:     '25',
      debug:                  'enabled',
      interval:               '5',
      manual_resume:          'disabled',
      receive_disable_string: 'disable string',
      receive_string:         'nou',
      reverse:                'disabled',
      send_string:            'GET Beep/\r\n',
      time_until_up:          '5',
      timeout:                '16',
      transparent:            'disabled',
      up_interval:            '5',
      provider:               described_class.name
    )
  end
  let(:provider) { resource.provider }

  before :each do
    allow(Facter).to receive(:value).with(:url).and_return('https://admin:admin@bigip')
    allow(Facter).to receive(:value).with(:feature)
  end

  describe 'instances' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_monitor/udp/instances') do
        result = provider.class.instances
      end
      expect(result.count).to eq(1)
    end
  end

  describe 'create' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_monitor/udp/create') do
        result = provider.create
        provider.flush
      end
      expect(result.status).to eq(200)
    end
  end

  describe 'flush' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_monitor/udp/flush') do
        provider.class.prefetch({ '/Common/udp' => resource})
        provider.transparent= 'enabled'
        result = provider.flush
      end
      expect(result.status).to eq(200)
    end
  end

  describe 'destroy' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_monitor/udp/destroy') do
        result = provider.destroy
        provider.flush
      end
      expect(result.status).to eq(200)
    end
  end
end
