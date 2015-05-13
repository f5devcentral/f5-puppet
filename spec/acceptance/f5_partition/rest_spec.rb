require 'spec_helper_acceptance'

describe 'f5_partition' do
  it 'creates a partition called pdx' do
    pp=<<-EOS
    f5_partition { 'pdx-partition':
      ensure      => 'present',
      description => 'PDX Staff',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'creates and updates a partition called bfs' do
    pp=<<-EOS
    f5_partition { 'bfs-partition':
      ensure      => 'present',
      description => 'BFS Staff',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_partition { 'bfs-partition':
      ensure      => 'present',
      description => 'Belfast Staff',
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'creates and deletes a partition called lhr' do
    pp=<<-EOS
    f5_partition { 'lhr-partition':
      ensure      => 'present',
      description => 'LHR Staff',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_partition { 'lhr-partition':
      ensure  => 'absent',
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'creates a basic node inside new partition' do
    pp=<<-EOS
    f5_partition { 'prg-partition':
      ensure      => 'present',
      description => 'Plzen Staff',
    }

    f5_node { '/prg-partition/node2':
      ensure  => 'present',
      address => '11.11.11.11',
      require => F5_partition['prg-partition']
    }
    EOS

    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'updates a basic node inside new partition' do
    pp=<<-EOS
    f5_partition { 'node3-partition':
      ensure      => 'present',
      description => 'New Partition',
    }

    f5_node { '/node3-partition/node3':
      ensure      => 'present',
      description => 'NORMAL',
      address => '11.11.11.33',
      require => F5_partition['node3-partition']
    }
    EOS

    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_partition { 'node3-partition':
      ensure      => 'present',
      description => 'New Partition',
    }

    f5_node { '/node3-partition/node3':
      ensure      => 'present',
      description => 'MODIFIED',
      require     => F5_partition['node3-partition']
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  it 'deletes a basic node inside new partition' do
    pp=<<-EOS
    f5_partition { 'node4-partition':
      ensure      => 'present',
      description => 'New Partition',
    }

    f5_node { '/node4-partition/node4':
      ensure      => 'present',
      description => 'NORMAL',
      address => '11.11.11.44',
      require => F5_partition['node4-partition']
    }
    EOS

    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_partition { 'node4-partition':
      ensure      => 'present',
      description => 'New Partition',
    }

    f5_node { '/node4-partition/node4':
      ensure  => 'absent',
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'creates a basic monitor inside new partition' do
    pp=<<-EOS
    f5_partition { 'monitor2-partition':
      ensure      => 'present',
      description => 'New Partition',
    }

    f5_monitor { '/monitor2-partition/monitor2':
      ensure   => 'present',
      provider => 'http',
      require  => F5_partition['monitor2-partition']
    }
    EOS

    make_site_pp(pp)
    run_device(:allow_changes => true)
  end

  it 'updates a basic monitor inside new partition' do
    pp=<<-EOS
    f5_partition { 'monitor3-partition':
      ensure      => 'present',
      description => 'New Partition',
    }

    f5_monitor { '/monitor3-partition/monitor3':
      ensure      => 'present',
      provider    => 'http',
      description => 'NORMAL',
      require     => F5_partition['monitor3-partition']
    }
    EOS

    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_partition { 'monitor3-partition':
      ensure      => 'present',
      description => 'New Partition',
    }

    f5_monitor { '/monitor3-partition/monitor3':
      ensure      => 'present',
      provider    => 'http',
      description => 'MODIFIED',
      require     => F5_partition['monitor3-partition']
    }
    EOS

    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'deletes a basic monitor inside new partition' do
    pp=<<-EOS
    f5_partition { 'monitor4-partition':
      ensure      => 'present',
      description => 'New Partition',
    }

    f5_monitor { '/monitor4-partition/monitor4':
      ensure      => 'present',
      provider    => 'http',
      description => 'NORMAL',
      require     => F5_partition['monitor4-partition']
    }
    EOS

    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_partition { 'monitor4-partition':
      ensure      => 'present',
      description => 'New Partition',
    }

    f5_monitor { '/monitor4-partition/monitor4':
      ensure   => 'absent',
      provider => 'http',
    }
    EOS

    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'creates a basic pool inside new partition' do
    pp=<<-EOS
    f5_partition { 'pool2-partition':
      ensure      => 'present',
      description => 'New Partition',
    }

    f5_pool { '/pool2-partition/pool2':
        ensure                   => 'present',
        availability_requirement => 'all',
        description              => 'NORMAL',
        health_monitors          => ['/Common/http'],
        require                  => F5_partition['pool2-partition']
      }
    EOS

    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'updates a basic pool inside new partition' do
    pp=<<-EOS
    f5_partition { 'pool3-partition':
      ensure      => 'present',
      description => 'New Partition',
    }

    f5_pool { '/pool3-partition/pool3':
        ensure                   => 'present',
        availability_requirement => 'all',
        description              => 'NORMAL',
        health_monitors          => ['/Common/http'],
        require                  => F5_partition['pool3-partition']
      }
    EOS

    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_partition { 'pool3-partition':
      ensure      => 'present',
      description => 'New Partition',
    }

    f5_pool { '/pool3-partition/pool3':
        ensure                   => 'present',
        availability_requirement => 'all',
        description              => 'UPDATED',
        health_monitors          => ['/Common/http'],
        require                  => F5_partition['pool3-partition']
      }
    EOS

    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'deletes a basic pool inside new partition' do
    pp=<<-EOS
    f5_partition { 'pool4-partition':
      ensure      => 'present',
      description => 'New Partition',
    }

    f5_pool { '/pool4-partition/pool4':
        ensure                   => 'present',
        availability_requirement => 'all',
        description              => 'NORMAL',
        health_monitors          => ['/Common/http'],
        require                  => F5_partition['pool4-partition']
      }
    EOS

    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_partition { 'pool4-partition':
      ensure      => 'present',
      description => 'New Partition',
    }

    f5_pool { '/pool4-partition/pool4':
        ensure  => 'absent',
      }
    EOS

    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  
end
