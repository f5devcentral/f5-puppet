require 'spec_helper'

describe Puppet::Type.type(:f5_monitor).provider(:ldap) do
  let(:resource) do
    Puppet::Type.type(:f5_monitor).new(
      name:                 '/Common/ldap_test',
      ensure:               :present,
      alias_address:        '*',
      alias_service_port:   '*',
      base:                 'ou=Base',
      chase_referrals:      'yes',
      debug:                'no',
      description:          'test',
      filter:               'ou=Filter',
      interval:             '10',
      mandatory_attributes: 'yes',
      manual_resume:        'disabled',
      username:             'apenney',
      password:             '$M$LT$/seJfDdtCIUdOHcIBdKfIA==',
      security:             'ssl',
      time_until_up:        '0',
      timeout:              '31',
      up_interval:          '0',
      provider:             described_class.name
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
      VCR.use_cassette('f5_monitor/ldap/instances') do
        result = provider.class.instances
      end
      expect(result.count).to eq(1)
    end
  end

  describe 'create' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_monitor/ldap/create') do
        result = provider.create
        provider.flush
      end
      expect(result.status).to eq(200)
    end
  end

  describe 'flush' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_monitor/ldap/flush') do
        provider.class.prefetch({ '/Common/ldap' => resource})
        provider.manual_resume= 'enabled'
        result = provider.flush
      end
      expect(result.status).to eq(200)
    end
  end

  describe 'destroy' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_monitor/ldap/destroy') do
        result = provider.destroy
        provider.flush
      end
      expect(result.status).to eq(200)
    end
  end
end
