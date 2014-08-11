require 'spec_helper'

describe Puppet::Type.type(:f5_monitor).provider(:external) do
  let(:resource) do
    Puppet::Type.type(:f5_monitor).new(
      name:               '/Common/external_test',
      ensure:             :present,
      alias_address:      '*',
      alias_service_port: '*',
      arguments:          'test',
      description:        'external',
      external_program:   '/Common/arg_example',
      interval:           '5',
      manual_resume:      'disabled',
      time_until_up:      '0',
      timeout:            '16',
      up_interval:        '0',
      variables:          {'userDefined test' => 'hi', 'userDefined test2' => 'hi'},
      provider:            described_class.name
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
      VCR.use_cassette('f5_monitor/external/instances') do
        result = provider.class.instances
      end
      expect(result.count).to eq(1)
    end
  end

  describe 'create' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_monitor/external/create') do
        result = provider.create
        provider.flush
      end
      expect(result.status).to eq(200)
    end
  end

  describe 'flush' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_monitor/external/flush') do
        provider.class.prefetch({ '/Common/external' => resource})
        provider.manual_resume= 'enabled'
        result = provider.flush
      end
      expect(result.status).to eq(200)
    end
  end

  describe 'destroy' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_monitor/external/destroy') do
        result = provider.destroy
        provider.flush
      end
      expect(result.status).to eq(200)
    end
  end
end
