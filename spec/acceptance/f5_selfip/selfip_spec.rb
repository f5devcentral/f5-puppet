require 'spec_helper_acceptance'

describe 'f5_selfip' do
  it 'creates test_vlan, other_vlan & selfip' do
    pp=<<-EOS
    f5_vlan { '/Common/test_vlan':
      ensure                 => 'present',
      auto_last_hop          => 'enabled',
      cmp_hash               => 'src-ip',
      dag_round_robin        => 'enabled',
      description            => 'This is VLAN 10',
      fail_safe              => 'enabled',
      fail_safe_action       => 'restart-all',
      fail_safe_timeout      => '90',
      mtu                    => '1500',
      sflow_polling_interval => '3000',
      sflow_sampling_rate    => '4000',
      source_check           => 'enabled',
      vlan_tag               => '10',
    }
      f5_vlan { '/Common/other_vlan':
      ensure                 => 'present',
      auto_last_hop          => 'enabled',
      cmp_hash               => 'src-ip',
      dag_round_robin        => 'enabled',
      description            => 'This is VLAN 11',
      fail_safe              => 'enabled',
      fail_safe_action       => 'restart-all',
      fail_safe_timeout      => '90',
      mtu                    => '1500',
      sflow_polling_interval => '3000',
      sflow_sampling_rate    => '4000',
      source_check           => 'enabled',
      vlan_tag               => '11',
    }
    f5_selfip { '/Common/test_self_ip':
      ensure                 => 'present',
      address                => '9.9.9.9/24',
      vlan                   => '/Common/test_vlan',
      traffic_group          => '/Common/traffic-group-local-only',
      port_lockdown          => ['default', 'gre:0', 'udp:0'],
      inherit_traffic_group  => 'false',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'edits selfip' do
    pp=<<-EOS
    f5_selfip { '/Common/test_self_ip':
      ensure                 => 'present',
      address                => '9.9.9.9/24',
      vlan                   => '/Common/other_vlan',
      traffic_group          => '/Common/traffic-group-local-only',
      port_lockdown          => ['none'],
      inherit_traffic_group  => 'false',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'delete a selfip' do
    pp=<<-EOS
    f5_selfip { '/Common/test_self_ip':
      ensure => 'absent',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'delete a test_vlan & other_vlan' do
    pp=<<-EOS
    f5_vlan { '/Common/test_vlan':
      ensure => 'absent',
    }
    f5_vlan { '/Common/other_vlan':
      ensure => 'absent',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

end
