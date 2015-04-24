require 'spec_helper_acceptance'

describe 'f5_monitor udp provider' do
  it 'creates a basic monitor called my_udp' do
    pp=<<-EOS
    f5_monitor { '/Common/my_udp':
      ensure   => 'present',
      provider => 'udp',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
