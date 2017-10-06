require 'spec_helper_acceptance'

describe 'f5_persistencessl' do
  it 'creates and updates f5_persistencessl' do
    pp=<<-EOS
    f5_persistencessl { '/Common/ssl1':
       ensure                          => 'present',
       mirror                          => 'enabled',
       match_across_pools              => 'enabled',
       match_across_services           => 'enabled',
       match_across_virtuals           => 'enabled',
       timeout                         => '180',
       override_connection_limit       => 'enabled',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_persistencessl { '/Common/ssl1':
       ensure                          => 'present',
       mirror                          => 'disabled',
       match_across_pools              => 'disabled',
       match_across_services           => 'disabled',
       match_across_virtuals           => 'disabled',
       timeout                         => '100',
       override_connection_limit       => 'disabled',
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)    
  end

  it 'deletes f5_persistencessl' do
    pp=<<-EOS
    f5_persistencessl { '/Common/ssl1':
      ensure => 'absent',
    }    
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)

  end
end

