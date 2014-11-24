require 'spec_helper_acceptance'

describe 'f5_monitor gateway_icmp provider' do
  it 'creates a basic monitor called my_gateway_icmp' do
    pp=<<-EOS
    f5_monitor { '/Common/my_gateway_icmp':
      ensure   => 'present',
      provider => 'gateway_icmp',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
