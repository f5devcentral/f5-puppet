require 'spec_helper_acceptance'

describe 'f5_vlan' do
  it 'creates a vlan called vlan10' do
    pp=<<-EOS
    f5_vlan { '/Common/vlan10':
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
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'creates and updates a vlan called vlan20' do
    pp=<<-EOS
    f5_vlan { '/Common/vlan20':
      ensure                 => 'present',
      auto_last_hop          => 'enabled',
      cmp_hash               => 'src-ip',
      dag_round_robin        => 'enabled',
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
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_vlan { '/Common/vlan20':
      ensure                 => 'present',
      auto_last_hop          => 'disabled',
      cmp_hash               => 'dst-ip',
      dag_round_robin        => 'disabled',
      description            => 'This is the VLAN 20',
      fail_safe              => 'disabled',
      fail_safe_action       => 'reboot',
      fail_safe_timeout      => '180',
      mtu                    => '1600',
      sflow_polling_interval => '5000',
      sflow_sampling_rate    => '6000',
      source_check           => 'disabled',
      vlan_tag               => '20',
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'creates and deletes a vlan called vlan30' do
    pp=<<-EOS
    f5_vlan { '/Common/vlan30':
      ensure                 => 'present',
      auto_last_hop          => 'enabled',
      cmp_hash               => 'src-ip',
      dag_round_robin        => 'enabled',
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
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_vlan { '/Common/vlan30':
      ensure  => 'absent',
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
