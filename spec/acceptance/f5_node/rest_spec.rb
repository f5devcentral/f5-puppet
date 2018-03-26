require 'spec_helper_acceptance'

describe 'f5_node' do
  it 'creates a basic node called my_node' do
    pp=<<-EOS
    f5_node { '/Common/my_node':
      ensure  => present,
      address => '10.10.10.10',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  it 'creates a node with a route domain' do
    pp=<<-EOS
    f5_node { '/Common/10.10.10.10%0':
      ensure  => present,
      address => '10.10.10.10',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  it 'updates a basic monitor called my_node' do
    pp=<<-EOS
    f5_node { '/Common/my_node':
      ensure      => 'present',
      description => 'MODIFIED',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  it 'deletes a node' do
    pp=<<-EOS
    f5_node { '/Common/my_node':
      ensure => 'absent',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  it 'sets health monitors, state, connection_limit, and ratio on my_node' do
    pp=<<-EOS
    f5_node { '/Common/my_node':
      ensure                   => present,
      address                  => '10.10.10.10',
      health_monitors          => '/Common/icmp',
      availability_requirement => 'all',
      ratio                    => '2',
      state                    => 'enabled',
      connection_limit         => '2',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  it 'sets availability_requirement to 1' do
    pp=<<-EOS
    f5_node { '/Common/my_node':
      ensure                   => present,
      address                  => '10.10.10.10',
      health_monitors          => '/Common/icmp',
      availability_requirement => '1',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  it 'sets ratio to 1' do
    pp=<<-EOS
    f5_node { '/Common/my_node':
      ensure                   => present,
      address                  => '10.10.10.10',
      health_monitors          => '/Common/icmp',
      availability_requirement => 'all',
      ratio                    => '1',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  it 'sets ratio to 100' do
    pp=<<-EOS
    f5_node { '/Common/my_node':
      ensure                   => present,
      address                  => '10.10.10.10',
      health_monitors          => '/Common/icmp',
      availability_requirement => 'all',
      ratio                    => '100',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  # Skip T844846
end
