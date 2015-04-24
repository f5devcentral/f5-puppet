require 'spec_helper_acceptance'

describe 'f5_monitor sip provider' do
  it 'creates a basic monitor called my_sip' do
    pp=<<-EOS
    f5_monitor { '/Common/my_sip':
      ensure   => 'present',
      provider => 'sip',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
