require 'spec_helper_acceptance'

describe 'f5_ntp' do

  it 'creates and updates ntp' do
    pp=<<-EOS
    f5_ntp { '/Common/ntp':
      servers               => ['0.pool.ntp.org', '1.pool.ntp.org'],
      timezone              => 'UTC',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_ntp { '/Common/ntp':
      servers               => ['2.pool.ntp.org', '3.pool.ntp.org'],
      timezone              => 'UTC',
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

end
