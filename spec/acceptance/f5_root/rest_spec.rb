require 'spec_helper_acceptance'

describe 'f5_root' do

  it 'updates root password' do
    pp=<<-EOS
    f5_root { '/Common/root':
      old_password               => 'default',
      new_password               => 'default',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

  end

end
