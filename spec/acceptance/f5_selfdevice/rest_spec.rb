require 'spec_helper_acceptance'

describe 'f5_root' do

  it 'rename the self device' do
    pp=<<-EOS
    f5_selfdevice { '/Common/bigip-a.f5.local':
      target          =>"bigip-a.f5.local",
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

  end

  it 'reset the self device' do
    pp=<<-EOS
    f5_selfdevice { '/Common/bigip1':
      target          =>"bigip1",
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
#    run_device(:allow_changes => false)
  end

end
