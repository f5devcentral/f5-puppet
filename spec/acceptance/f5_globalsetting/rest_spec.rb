require 'spec_helper_acceptance'

describe 'f5_globalsetting' do

  it 'creates and updates global setting' do
    pp=<<-EOS
f5_globalsetting { '/Common/globalsetting':
      hostname               => "bigip-1.f5.local",
      gui_setup               => "disabled",
 }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
f5_globalsetting { '/Common/globalsetting':
      hostname               => "bigip-a.f5.local",
      gui_setup               => "disabled",
 }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

end
