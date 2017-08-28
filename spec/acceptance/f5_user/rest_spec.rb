require 'spec_helper_acceptance'

describe 'f5_user' do
  it 'creates a user called joe' do
    pp=<<-EOS
    f5_user { '/Common/joe':
      name                   => 'joe',
      ensure                 => 'present',
      password               => 'joe',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
#    run_device(:allow_changes => false)
  end

  it 'creates and updates a user called alice' do
    pp=<<-EOS
    f5_user { '/Common/alice':
      name                   => 'alice',
      ensure                 => 'present',
      password               => 'alice',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_user { '/Common/alice':
      name                   => 'alice',
      ensure                 => 'present',
      password               => 'alice1',
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
#    run_device(:allow_changes => false)
  end

  it 'deletes users joe and aliace' do
    pp=<<-EOS
    f5_user { '/Common/joe':
      name                   => 'joe',
      ensure                 => 'absent',
    }
    f5_user { '/Common/alice':
      name                   => 'alice',
      ensure                 => 'absent',
    }    
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)

  end
end

