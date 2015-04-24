require 'spec_helper_acceptance'

describe 'f5_monitor ldap provider' do
  it 'creates a basic monitor called my_ldap' do
    pp=<<-EOS
    f5_monitor { '/Common/my_ldap':
      ensure   => 'present',
      provider => 'ldap',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
