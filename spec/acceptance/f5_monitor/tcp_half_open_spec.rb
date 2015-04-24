require 'spec_helper_acceptance'

describe 'f5_monitor tcp_half_open provider' do
  it 'creates a basic monitor called my_tcp_half_open' do
    pp=<<-EOS
    f5_monitor { '/Common/my_tcp_half_open':
      ensure   => 'present',
      provider => 'tcp_half',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
