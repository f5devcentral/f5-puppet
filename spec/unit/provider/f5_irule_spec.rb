require 'spec_helper'

describe Puppet::Type.type(:f5_irule).provider(:rest) do
  let(:resource) do
    Puppet::Type.type(:f5_irule).new(
      name:             '/Common/test_irule',
      ensure:           :present,
      definition:       'when HTTP_REQUEST {
       HTTP::redirect https://[getfield [HTTP::host] ":" 1][HTTP::uri]
    }
definition-signature mwyl4XlRKRMQc0prWs7RtpgPcNfocOKb+MaFwAnQgAuUZZyG68OaGZsOCN3poUOFdHOc6fk2XAdGRmTRiP/7BCT7thsOX5zLFzA1N1wcr57KWVzEZt3ezxVXn2Z974OmbWm7P5Lclcr7N3adrLJMWfyfPPVF1tUYn0IQPD2QNMmfbcbr1oCuO93n/5dn0s6/EacHZGG53hVibW7xQuJXdMtoQ6ArSZ4U3n4vCDTb6NLYbAj6PirVzKY2pcsWFHFUSVrphSFwERc8+0XGHUE6Cb3ihzygoZc2cQ5jk3frFY70MkDluPTShFRbHd7PlMPRezrfkVZVeUHA/iBPcYcD+w==',
      verify_signature: true,
      provider:         described_class.name)
  end
  let(:provider) { resource.provider }

  before :each do
    allow(Facter).to receive(:value).with(:url).and_return('https://admin:admin@bigip')
    allow(Facter).to receive(:value).with(:feature)
  end

  describe 'instances' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_irule/instances') do
        result = provider.class.instances
      end
      expect(result.count).to eq(11)
    end
  end

  describe 'create' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_irule/create') do
        result = provider.create
      end
      expect(result.status).to eq(200)
    end
  end

  describe 'flush' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_irule/flush') do
        provider.class.prefetch({ '/Common/test_irule' => resource})
        provider.verify_signature= false
        result = provider.flush
      end
      expect(result.status).to eq(200)
    end
  end

  describe 'destroy' do
    it 'gets a response from the api' do
      result = nil
      VCR.use_cassette('f5_irule/destroy') do
        result = provider.destroy
      end
      expect(result.status).to eq(200)
    end
  end
end
