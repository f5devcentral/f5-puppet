require 'spec_helper_acceptance'

describe 'f5_monitor https provider' do
  it 'creates a basic monitor called my_https' do
    pp=<<-EOS
    f5_monitor { '/Common/my_https':
      ensure   => 'present',
      provider => 'https',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
