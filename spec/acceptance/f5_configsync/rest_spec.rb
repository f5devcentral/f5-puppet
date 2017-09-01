require 'spec_helper_acceptance'

describe 'f5_configsync' do

  it 'execute tmsh command' do
    pp=<<-EOS
    f5_configsync { '/Common/config-sync':
      to_group => "DeviceGroup1",
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

  end

end
