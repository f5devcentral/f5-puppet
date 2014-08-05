require 'spec_helper'

describe Puppet::Type.type(:f5_monitor).provider(:https) do
  let(:resource) do
    Puppet::Type.type(:f5_monitor).new(
      name:           '/Common/test',
      ensure:         :present,
      description:    'test2',
      destination:    '10.0.0.1:22',
      interval:       '6',
      manual_resume:  'enabled',
      password:       '$M$d4$5H0MvmBC4iyrohIzS0eBqg==',
      receive_string: 'nou',
      reverse:        'disabled',
      send_string:    'GET Beep/\r\n',
      time_until_up:  '5',
      timeout:        '17',
      transparent:    'disabled',
      up_interval:    '0',
      provider:      described_class.name)
  end
  let(:provider) { resource.provider }

  before :each do
    allow(Facter).to receive(:value).with(:url).and_return('https://admin:admin@bigip')
    allow(Facter).to receive(:value).with(:feature)
  end

  describe 'instances' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_monitor/http/instances') do
        result = provider.class.instances
      end
      expect(result.count).to eq(2)
    end
  end

  describe 'create' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_monitor/http/create') do
        result = provider.create
      end
      expect(result.status).to eq(200)
    end
  end

  describe 'flush' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_monitor/http/flush') do
        provider.class.prefetch({ '/Common/tcphalf' => resource})
        provider.transparent= 'enabled'
        result = provider.flush
      end
      expect(result.status).to eq(200)
    end
  end

  describe 'destroy' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_monitor/http/destroy') do
        result = provider.destroy
      end
      expect(result.status).to eq(200)
    end
  end


end
