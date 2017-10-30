require 'spec_helper_acceptance'

describe 'f5_snat' do
  it 'creates and updates f5_snat' do
    pp=<<-EOS
    f5_snatpool { '/Common/snat_pool1':
       ensure  => 'present',
       members => ["/Common/1.1.1.1"],
    }
    f5_snat { '/Common/snat_list1':
       ensure   => 'present',
       snatpool => ['/Common/snat_pool1'],
       origins  => [{"name"=>"10.0.0.0/8"}],
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_snat { '/Common/snat_list1':
       ensure   => 'present',
       snatpool => ['/Common/snat_pool1'],
       origins  => [{"name"=> "10.0.0.0/8"}, {"name"=> "11.0.0.0/8"}],
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)    
  end

  it 'deletes f5_snat' do
    pp=<<-EOS
    f5_snat { '/Common/snat_list1':
      ensure => 'absent',
    }    
    f5_snatpool { '/Common/snat_pool1':
      ensure => 'absent',
    } 
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)

  end
end

