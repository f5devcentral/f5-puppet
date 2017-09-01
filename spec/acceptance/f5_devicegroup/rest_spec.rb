require 'spec_helper_acceptance'

describe 'f5_devicegroup' do

  it 'create device group' do
    pp=<<-EOS
    f5_selfdevice { '/Common/bigip-a.f5.local':
      target          =>"bigip-a.f5.local",
    }
        
    f5_devicegroup{ '/Common/DeviceGroup1':
      ensure              => 'present',
      type                => 'sync-failover',
      auto_sync           => 'enabled',
      devices             => [ "bigip-a.f5.local","bigip-b.f5.local" ],
  #   devices             => [ "bigip-a.f5.local"],
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

  end

end
