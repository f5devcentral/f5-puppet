require 'spec_helper_acceptance'

describe 'f5_route' do
  it 'creates test_vlan, selfip & default route' do
    pp=<<-EOS
    f5_vlan { '/Common/test_vlan':
      ensure                 => 'present',
      auto_last_hop          => 'enabled',
      cmp_hash               => 'src-ip',
      description            => 'This is VLAN 20',
      fail_safe              => 'enabled',
      fail_safe_action       => 'restart-all',
      fail_safe_timeout      => '90',
      mtu                    => '1500',
      sflow_polling_interval => '3000',
      sflow_sampling_rate    => '4000',
      source_check           => 'enabled',
      vlan_tag               => '20',
    }
    f5_selfip { '/Common/test_self_ip':
      ensure                 => 'present',
      address                => '10.1.20.1/24',
      vlan                   => '/Common/test_vlan',
      traffic_group          => '/Common/traffic-group-local-only',
      port_lockdown          => ['default', 'gre:0', 'udp:0'],
      inherit_traffic_group  => 'false',
    }
    f5_route { '/Common/Default1':
      ensure           => 'present',
      gw               => "10.1.20.253",
      mtu              => '0',
      network          => "10.0.0.0/8",
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'edits default route' do
    pp=<<-EOS
    f5_route { '/Common/Default1':
      ensure           => 'present',
      gw               => "10.1.20.254",
      mtu              => '1000',
      network          => "10.0.0.0/8",
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'delete default route' do
    pp=<<-EOS
    f5_route { '/Common/Default1':
      ensure           => 'absent',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'delete a test_vlan & test_self_ip' do
    pp=<<-EOS
    f5_selfip { '/Common/test_self_ip':
      ensure => 'absent',
    }
    f5_vlan { '/Common/test_vlan':
      ensure => 'absent',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

end
