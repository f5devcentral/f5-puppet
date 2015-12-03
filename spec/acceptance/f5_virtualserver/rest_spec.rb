require 'spec_helper_acceptance'

describe 'f5_virtualserver' do
  it 'creates and updates virtualserver named my_standard_vs of type Standard' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_standard_vs':
      ensure          => 'present',
      provider        => 'standard',
      service_port    => '4321',
      ipother_profile => '/Common/ipother',
      protocol        => 'all',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_virtualserver { '/Common/my_standard_vs':
      ensure          => 'present',
      provider        => 'standard',
      description     => 'MODIFIED PORT',
      service_port    => '54321',
      ipother_profile => '/Common/ipother',
      protocol        => 'all',
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'creates and updates virtualserver named my_forwarding_ip_vs of type forwarding_ip' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_forwarding_ip_vs':
      ensure => 'present',
      provider => 'forwarding_ip',
      service_port => '4322',
      http_profile => '/Common/http',
      protocol => 'tcp',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_virtualserver { '/Common/my_forwarding_ip_vs':
      ensure => 'present',
      provider => 'forwarding_ip',
      service_port => '54322',
      http_profile => '/Common/http',
      protocol => 'tcp'
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'deletes virtualserver named my_forwarding_ip_vs' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_forwarding_ip_vs':
      ensure => 'absent',
      provider => 'forwarding_ip',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'creates and updates virtualserver named my_forwarding_layer_2_vs of type forwarding_layer_2' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_forwarding_layer_2_vs':
      ensure => 'present',
      provider => 'forwarding_layer_2',
      service_port => '4323',
      http_profile => '/Common/http',
      protocol => 'tcp',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_virtualserver { '/Common/my_forwarding_layer_2_vs':
      ensure => 'present',
      provider => 'forwarding_layer_2',
      service_port => '54323',
      http_profile => '/Common/http',
      protocol => 'tcp',
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'deletes virtualserver named my_forwarding_layer_2_vs' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_forwarding_layer_2_vs':
      ensure => 'absent',
      provider => 'forwarding_layer_2',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'creates and updates virtualserver named my_performance_http_vs of type performance_http' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_performance_http_vs':
      ensure => 'present',
      provider => 'performance_http',
      service_port => '4324',
      protocol_profile_client => '/Common/fasthttp',
      protocol => 'tcp',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_virtualserver { '/Common/my_performance_http_vs':
      ensure => 'present',
      provider => 'performance_http',
      service_port => '54324',
      protocol_profile_client => '/Common/fasthttp',
      protocol => 'tcp',
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'deletes virtualserver named my_performance_http_vs' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_performance_http_vs':
      ensure => 'absent',
      provider => 'performance_http',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'creates and updates virtualserver named my_performance_l4_vs of type performance_l4' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_performance_l4_vs':
      ensure => 'present',
      provider => 'performance_l4',
      service_port => '4325',
      protocol_profile_client => '/Common/fastL4',
      protocol => 'tcp',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_virtualserver { '/Common/my_performance_l4_vs':
      ensure => 'present',
      provider => 'performance_l4',
      service_port => '54325',
      protocol_profile_client => '/Common/fastL4',
      protocol => 'tcp',
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'deletes virtualserver named my_performance_l4_vs' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_performance_l4_vs':
      ensure => 'absent',
      provider => 'performance_l4',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'creates and updates virtualserver named my_reject_vs of type reject' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_reject_vs':
      ensure => 'present',
      provider => 'reject',
      service_port => '4326',
      http_profile => '/Common/http',
      protocol => 'tcp',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_virtualserver { '/Common/my_reject_vs':
      ensure => 'present',
      provider => 'reject',
      service_port => '54326',
      http_profile => '/Common/http',
      protocol => 'tcp',
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'deletes virtualserver named my_reject_vs' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_reject_vs':
      ensure => 'absent',
      provider => 'reject',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'creates and updates virtualserver named my_stateless_vs of type stateless' do
    pp=<<-EOS
    f5_pool { '/Common/my_stateless_pool':
      ensure => 'present',
      load_balancing_method => 'round-robin',
    }
    f5_virtualserver { '/Common/my_stateless_vs':
      ensure => 'present',
      provider => 'stateless',
      default_pool => '/Common/my_stateless_pool',
      protocol => 'udp',
      destination_address => '0.0.0.0',
      service_port => '0',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_pool { '/Common/my_stateless_pool':
      ensure => 'present',
      load_balancing_method => 'round-robin',
    }
    f5_virtualserver { '/Common/my_stateless_vs':
      ensure => 'present',
      provider => 'stateless',
      default_pool => '/Common/my_stateless_pool',
      protocol => 'udp',
      destination_address => '0.0.0.0',
      service_port => '50000',
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'deletes virtualserver named my_stateless_vs and pool named my_stateless_pool' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_stateless_vs':
      ensure => 'absent',
      provider => 'stateless',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_pool { '/Common/my_stateless_pool':
      ensure => 'absent',
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'add resource HTTP Profile to virtualserver named my_standard_vs' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_standard_vs':
      ensure => 'present',
      provider => 'standard',
      description => 'MODIFIED HTTP Profile',
      service_port => '54321',
      http_profile => '/Common/http',
      protocol => 'tcp',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'add resource iRules to virtualserver named my_standard_vs' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_standard_vs':
      ensure => 'present',
      provider => 'standard',
      description => 'MODIFIED iRules',
      service_port => '54321',
      http_profile => '/Common/http',
      protocol => 'tcp',
      irules => ['/Common/_sys_https_redirect'],
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'add resource default persistence profile to virtualserver named my_standard_vs' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_standard_vs':
      ensure => 'present',
      provider => 'standard',
      description => 'MODIFIED Default Persistence',
      service_port => '54321',
      http_profile => '/Common/http',
      protocol => 'tcp',
      irules => ['/Common/_sys_https_redirect'],
      default_persistence_profile => '/Common/universal',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'disables and enables virtualserver named my_standard_vs of type Standard' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_standard_vs':
      ensure => 'present',
      provider => 'standard',
      state => 'disabled',
      description => 'MODIFIED State',
      service_port => '54321',
      http_profile => '/Common/http',
      protocol => 'tcp',
      irules => ['/Common/_sys_https_redirect'],
      default_persistence_profile => '/Common/universal',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_virtualserver { '/Common/my_standard_vs':
      ensure => 'present',
      provider => 'standard',
      state => 'enabled',
      description => 'MODIFIED State',
      service_port => '54321',
      http_profile => '/Common/http',
      protocol => 'tcp',
      irules => ['/Common/_sys_https_redirect'],
      default_persistence_profile => '/Common/universal',
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'delete resource default persistence profile from virtualserver named my_standard_vs' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_standard_vs':
      ensure => 'present',
      provider => 'standard',
      description => 'Removed Default Persistence',
      service_port => '54321',
      http_profile => '/Common/http',
      protocol => 'tcp',
      irules => ['/Common/_sys_https_redirect'],
      default_persistence_profile => 'none',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'delete resource iRules from virtualserver named my_standard_vs' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_standard_vs':
      ensure => 'present',
      provider => 'standard',
      description => 'Removed iRule',
      service_port => '54321',
      http_profile => '/Common/http',
      protocol => 'tcp',
      irules => ['none'],
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'delete resource HTTP Profile from virtualserver named my_standard_vs' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_standard_vs':
      ensure => 'present',
      provider => 'standard',
      description => 'Removed HTTP Profile',
      service_port => '54321',
      http_profile => 'none',
      protocol => 'all',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
    expect(run_resource('f5_virtualserver','/Common/my_standard_vs')).to match(%r{Removed HTTP Profile})
  end

  it 'deletes virtualserver named my_standard_vs' do
    pp=<<-EOS
    f5_virtualserver { '/Common/my_standard_vs':
      ensure => 'absent',
      provider => 'standard',
      protocol => 'all',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
