require 'spec_helper_acceptance'

describe 'f5_pool' do
  [
    'gateway_icmp',
    'http',
    'https',
    'https_443',
    'http_head_f5',
    'inband',
    'https_head_f5',
    'tcp_half_open',
    'tcp',
    'udp',
  ].each do |monitor|
    it "sets health_monitors for #{monitor}" do
      pp=<<-EOS
      f5_pool { '/Common/my_pool':
        ensure                   => 'present',
        availability_requirement => 'all',
        health_monitors          => ['/Common/#{monitor}'],
      }
      EOS
      make_site_pp(pp)
      run_device()
      expect(run_resource('f5_pool','/Common/my_pool')).to match(%r{#{monitor}})
    end
  end
end
