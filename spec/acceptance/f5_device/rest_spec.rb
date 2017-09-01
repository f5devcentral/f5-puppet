require 'spec_helper_acceptance'

describe 'f5_route' do
  it 'creates test_ha_vlan, test_ha_selfip & route' do
    pp=<<-EOS
    f5_vlan { '/Common/test_ha_vlan':
      ensure                 => 'present',
      auto_last_hop          => 'enabled',
      cmp_hash               => 'src-ip',
      description            => 'This is VLAN 30',
      fail_safe              => 'enabled',
      fail_safe_action       => 'restart-all',
      fail_safe_timeout      => '90',
      mtu                    => '1500',
      sflow_polling_interval => '3000',
      sflow_sampling_rate    => '4000',
      source_check           => 'enabled',
      vlan_tag               => '30',
    }
    f5_selfip { '/Common/test_ha_selfip':
      ensure                 => 'present',
      address                => '10.1.30.1/24',
      vlan                   => '/Common/test_ha_vlan',
      traffic_group          => '/Common/traffic-group-local-only',
      port_lockdown          => ['default', 'gre:0', 'udp:0'],
      inherit_traffic_group  => 'false',
    }
    f5_selfdevice { '/Common/bigip-a.f5.local':
      target          =>"bigip-a.f5.local",
    }
    f5_device{ '/Common/bigip-a.f5.local':
      ensure                           => 'present',
      configsync_ip                    => '10.1.30.1',
      mirror_ip                        => '10.1.30.1',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
#    run_device(:allow_changes => false)
  end


  it 'delete a test_vlan & test_self_ip' do
    pp=<<-EOS

    f5_device{ '/Common/bigip-a.f5.local':
      ensure                           => 'present',
      configsync_ip                    => 'none',
      mirror_ip                        => 'any6',
    }
    f5_selfdevice { '/Common/bigip1':
      target          =>"bigip1",
    }    
    f5_selfip { '/Common/test_ha_selfip':
      ensure => 'absent',
    }
    f5_vlan { '/Common/test_ha_vlan':
      ensure => 'absent',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
  #  run_device(:allow_changes => false)
  end

end
