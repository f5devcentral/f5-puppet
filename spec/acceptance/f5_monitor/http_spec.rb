require 'spec_helper_acceptance'

describe 'f5_monitor http provider' do
  it 'creates a basic monitor called my_http' do
    pp=<<-EOS
    f5_monitor { '/Common/my_http':
      ensure   => 'present',
      provider => 'http',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  it 'updates a basic monitor called my_http' do
    pp=<<-EOS
    f5_monitor { '/Common/my_http':
      ensure      => 'present',
      provider    => 'http',
      description => 'MODIFIED',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  it 'works with transparent and reverse' do
    pp=<<-EOS
    f5_monitor { '/Common/http_transparent_reverse':
      ensure             => 'present',
      provider           => 'http',
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
  it 'deletes a monitor' do
    pp=<<-EOS
    f5_monitor { '/Common/my_http':
      ensure   => 'absent',
      provider => 'http',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
