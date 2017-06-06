require 'spec_helper_acceptance'

describe 'f5_iapp' do
  it 'creates a basic iapp called my_iapp' do
    pp=<<-EOS
    f5_iapp { '/Common/my_iapp.app/my_iapp':
      ensure    => present,
      template  => '/Common/f5.bea_weblogic',
      tables    => {
        'basic__snatpool_members' => [],
        'net__snatpool_members'   => [],
        'optimizations__hosts'    => [],
        'server_pools__servers'   => [],
        'pool__hosts'             => [
          { 'name' => 'fqdn.host.com' },
        ],
        'pool__members' => [
          {
            'addr'             => '',
            'connection_limit' => '0',
            'port'             => '7001',
          },
        ],
      },
      variables => {
        'client__http_compression'           => '/#create_new#',
        'monitor__monitor'                   => '/#create_new#',
        'monitor__response'                  => 'none',
        'monitor__uri'                       => '/',
        'net__client_mode'                   => 'wan',
        'net__server_mode'                   => 'lan',
        'pool__addr'                         => '10.0.0.1',
        'pool__pool_to_use'                  => '/#create_new#',
        'pool__port'                         => '7001',
        'ssl__mode'                          => 'no_ssl',
        'ssl_encryption_questions__advanced' => 'no',
        'ssl_encryption_questions__help'     => 'hide',
      },
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  it 'updates a basic iapp called my_iapp' do
    pp=<<-EOS
    f5_iapp { '/Common/my_iapp.app/my_iapp':
      ensure    => present,
      template  => '/Common/f5.bea_weblogic',
      tables    => {
        'basic__snatpool_members' => [],
        'net__snatpool_members'   => [],
        'optimizations__hosts'    => [],
        'server_pools__servers'   => [],
        'pool__hosts'             => [
          { 'name' => 'fqdn.host.com' },
        ],
        'pool__members' => [
          {
            'addr'             => '',
            'connection_limit' => '0',
            'port'             => '7002',
          },
        ],
      },
      variables => {
        'client__http_compression'           => '/#create_new#',
        'monitor__monitor'                   => '/#create_new#',
        'monitor__response'                  => 'none',
        'monitor__uri'                       => '/',
        'net__client_mode'                   => 'wan',
        'net__server_mode'                   => 'lan',
        'pool__addr'                         => '10.0.0.1',
        'pool__pool_to_use'                  => '/#create_new#',
        'pool__port'                         => '7002',
        'ssl__mode'                          => 'no_ssl',
        'ssl_encryption_questions__advanced' => 'no',
        'ssl_encryption_questions__help'     => 'hide',
      },
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
    expect(run_resource('f5_virtualserver', '/Common/my_iapp.app/my_iapp_vs')).to match(%{7002})
  end
  it 'deletes a iapp' do
    pp=<<-EOS
    f5_iapp { '/Common/my_iapp.app/my_iapp':
      ensure   => 'absent',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
