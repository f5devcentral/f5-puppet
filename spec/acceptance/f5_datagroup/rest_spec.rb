require 'spec_helper_acceptance'

describe 'f5_datagroup' do
  it 'creates and updates f5_datagroup' do
    pp=<<-EOS
    f5_datagroup { '/Common/datagroup1':
       ensure                          => 'present',
       type                            => 'ip',
       records                         => [{data => '', name => '64.12.96.0/19'}],
    }
    f5_datagroup { '/Common/datagroup2':
       ensure                          => 'present',
       type                            => 'string',
       records                         => [{data => '', name => '.gif'}],
    }
    f5_datagroup { '/Common/datagroup3':
       ensure                          => 'present',
       type                            => 'integer',
       records                         => [{data => '', name => '1'}],
    }    
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_datagroup { '/Common/datagroup1':
       ensure                          => 'present',
       type                            => 'ip',
       records                         => [{'data' => '', 'name' => '64.12.96.0/19'}, {'data' => '', 'name' => '195.93.16.0/20'}],
    }

    f5_datagroup { '/Common/datagroup2':
       ensure                          => 'present',
       type                            => 'string',
       records                         => [{'data' => '', 'name' => '.gif'}, {'data' => '', 'name' => '.jpg'}],
    }

    f5_datagroup { '/Common/datagroup3':
       ensure                          => 'present',
       type                            => 'integer',
       records                         => [{'data' => '', 'name' => '1'}, {'data' => '', 'name' => '2'}],
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)    
  end

  it 'deletes f5_datagroup' do
    pp=<<-EOS
    f5_datagroup { '/Common/datagroup1':
      ensure => 'absent',
    }    
    f5_datagroup { '/Common/datagroup2':
      ensure => 'absent',
    }  
    f5_datagroup { '/Common/datagroup3':
      ensure => 'absent',
    }      
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)

  end
end

