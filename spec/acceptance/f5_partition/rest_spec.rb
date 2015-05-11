require 'spec_helper_acceptance'

describe 'f5_partition' do
  it 'creates a partition called pdx' do
    pp=<<-EOS
    f5_partition { 'pdx-partition':
      ensure      => present,
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
      ensure      => present,
      description => 'BFS Staff',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_partition { 'bfs-partition':
      ensure      => present,
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
      ensure      => present,
      description => 'LHR Staff',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_partition { 'lhr-partition':
      ensure  => absent,
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

  it 'creates a basic node called node2 inside partition PRG' do
    pp=<<-EOS
    f5_partition { 'prg-partition':
      ensure      => present,
      description => 'Plzen Staff',
    }

    f5_node { '/prg-partition/node2':
      ensure  => present,
      address => '11.11.11.11',
      require => F5_partition['prg-partition']
    }
    EOS

    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  
end
