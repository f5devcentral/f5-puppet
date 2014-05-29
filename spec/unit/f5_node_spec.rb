require 'spec_helper'

describe 'f5_node' do
  let(:connection) do
    Faraday::Connection.new(:url => 'https://admin:admin@bigip', :ssl => {:verify => false})
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
end
