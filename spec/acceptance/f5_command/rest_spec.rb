require 'spec_helper_acceptance'

describe 'f5_command' do

  it 'execute tmsh command' do
    pp=<<-EOS
    f5_command { '/Common/tmsh':
      tmsh => {
        command         => "mv",
        name            =>"bigip1",
        target          =>"bigip-a.f5.local",
      }
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

  end

end
