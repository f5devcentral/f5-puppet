require 'spec_helper_acceptance'

describe 'f5_monitor tcp provider' do
  it 'creates a basic monitor called my_tcp' do
    pp=<<-EOS
    f5_monitor { '/Common/my_tcp':
      ensure   => 'present',
      provider => 'tcp',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  it 'works with transparent and reverse' do
    pp=<<-EOS
    f5_monitor { '/Common/tcp_transparent_reverse':
      ensure             => 'present',
      provider           => 'tcp',
      alias_address      => '10.10.10.8',
      alias_service_port => '80',
      receive_string     => 'foo',
      reverse            => 'enabled',
      transparent        => 'enabled',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
