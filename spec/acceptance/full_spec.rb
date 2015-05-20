require 'spec_helper_acceptance'

describe 'full f5 setup' do
  it 'creates all the things' do
    pp=<<-EOS
      f5_partition { 'poc-partition':
        ensure => 'present',
        description => 'F5 for all the things',
      }
      f5_monitor { '/poc-partition/my-udp':
        ensure   => 'present',
        provider => 'udp',
        require  => F5_partition['poc-partition'],
        before   => F5_pool['/poc-partition/google-pool'],
      }
      f5_node { '/poc-partition/google-1':
        ensure      => 'present',
        address     => '8.8.8.8',
        require     => F5_partition['poc-partition'],
        before      => F5_pool['/poc-partition/google-pool'],
      }
      f5_node { '/poc-partition/google-2':
        ensure      => 'present',
        address     => '8.8.4.4',
        require     => F5_partition['poc-partition'],
        before      => F5_pool['/poc-partition/google-pool'],
      }
      f5_pool { '/poc-partition/google-pool':
        ensure                   => 'present',
        availability_requirement => 'all',
        health_monitors          => ['/poc-partition/my-udp'],
        members                  => [
                                      { 'name' => '/poc-partition/google-1', 'port' => 53 },
                                      { 'name' => '/poc-partition/google-2', 'port' => 53 },
                                    ],
      }
      f5_virtualserver { '/poc-partition/google-dns':
        destination_address => '10.10.1.1',
        service_port        => 53,
        provider            => 'standard',
        protocol            => 'udp',
        default_pool        => '/poc-partition/google-pool',
        require             => F5_pool['/poc-partition/google-pool'],
      }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
