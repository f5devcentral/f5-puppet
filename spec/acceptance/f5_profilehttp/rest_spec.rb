require 'spec_helper_acceptance'

describe 'f5_profilehttp' do
  it 'creates and updates f5_profilehttp' do
    pp=<<-EOS
    f5_profilehttp { '/Common/http-profile_1':
       ensure                          => 'present',
       fallback_host                   => "redirector.siterequest.com",
       fallback_status_codes           => ['500'],
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    # pp2=<<-EOS
    # f5_persistencedestaddr { '/Common/dest_addr1':
    #    ensure                          => 'present',
    #    match_across_pools              => 'disabled',
    #    match_across_services           => 'disabled',
    #    match_across_virtuals           => 'disabled',
    #    hash_algorithm                  => 'default',
    #    mask                            => '255.255.0.0',
    #    timeout                         => '100',
    #    override_connection_limit       => 'disabled',
    # }
    # EOS
    # make_site_pp(pp2)
    # run_device(:allow_changes => true)
    # run_device(:allow_changes => false)    
  end

  it 'deletes f5_profilehttp' do
    pp=<<-EOS
    f5_profilehttp { '/Common/http-profile_1':
      ensure => 'absent',
    }    
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)

  end
end

