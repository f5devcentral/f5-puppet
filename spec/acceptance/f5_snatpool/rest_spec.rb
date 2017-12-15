require 'spec_helper_acceptance'

describe 'f5_snatpool' do
  it 'creates and updates f5_snatpool' do
    pp=<<-EOS
    f5_snatpool { '/Common/snat_pool1':
       ensure  => 'present',
       members => ["/Common/1.1.1.1"],
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_snatpool { '/Common/snat_pool1':
       ensure  => 'present',
       members => ["/Common/1.1.1.1", "/Common/1.1.1.2", "/Common/1.1.1.3"],
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)    
  end

  it 'deletes f5_snatpool' do
    pp=<<-EOS
    f5_snatpool { '/Common/snat_pool1':
      ensure => 'absent',
    }    
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)

  end
end

