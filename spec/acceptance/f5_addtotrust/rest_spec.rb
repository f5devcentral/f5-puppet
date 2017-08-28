require 'spec_helper_acceptance'

describe 'f5_addtotrust' do

  it 'add device to trust' do
    pp=<<-EOS
    f5_addtotrust { '/Common/addtotrust':
      device       => "10.192.74.112",
      deviceName   => "bigip-b.f5.local",
      username     => "admin",
      password     => "admin",
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

  end

end
