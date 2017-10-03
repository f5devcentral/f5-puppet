require 'spec_helper_acceptance'

describe 'f5_persistencecookie' do
  it 'creates and updates f5_persistencecookie cookie1' do
    pp=<<-EOS
    f5_persistencecookie { '/Common/cookie1':
      ensure            => 'present',
      method            => 'insert',
      cookie_name       => 'name1',
      httponly          => 'enabled',
      secure            => 'enabled',
      always_send       => 'disabled',
      expiration        => '0',
      cookie_encryption => 'disabled',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_persistencecookie { '/Common/cookie1':
      ensure            => 'present',
      method            => 'passive',
      cookie_name       => 'name1',
      httponly          => 'disabled',
      secure            => 'disabled',
      always_send       => 'enabled',
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)    
  end

  it 'deletes f5_persistencecookie cookie1' do
    pp=<<-EOS
    f5_persistencecookie { '/Common/cookie1':
      ensure                 => 'absent',
    }    
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)

  end
end

