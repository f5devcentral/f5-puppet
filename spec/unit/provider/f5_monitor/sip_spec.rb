require 'spec_helper'

describe Puppet::Type.type(:f5_monitor).provider(:sip) do
  let(:resource) do
    Puppet::Type.type(:f5_monitor).new(
      name:                             '/Common/sip_test',
      ensure:                           :present,
      additional_accepted_status_codes: [ '100', '101', '102' ],
      additional_rejected_status_codes: '*',
      alias_address:                    '*',
      alias_service_port:               '*',
      debug:                            'no',
      description:                      'sip test',
      header_list:                      ['test', 'test2'],
      interval:                         '5',
      manual_resume:                    'disabled',
      mode:                             'udp',
      sip_request:                      'yes please',
      time_until_up:                    '0',
      timeout:                          '16',
      up_interval:                      '0',
      provider:                         described_class.name
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
      VCR.use_cassette('f5_monitor/sip/instances') do
        result = provider.class.instances
      end
      expect(result.count).to eq(1)
    end
  end

  describe 'create' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_monitor/sip/create') do
        result = provider.create
        provider.flush
      end
      expect(result.status).to eq(200)
    end
  end

  describe 'flush' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_monitor/sip/flush') do
        provider.class.prefetch({ '/Common/sip' => resource})
        provider.manual_resume= 'enabled'
        result = provider.flush
      end
      expect(result.status).to eq(200)
    end
  end

  describe 'destroy' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_monitor/sip/destroy') do
        result = provider.destroy
        provider.flush
      end
      expect(result.status).to eq(200)
    end
  end
end
