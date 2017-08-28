require 'spec_helper_acceptance'

describe 'f5_dns' do

  it 'creates and updates dns' do
    pp=<<-EOS
    f5_dns { '/Common/dns':
      name_servers         => ["4.2.2.2", "8.8.8.8"],
      search               => ["localhost","f5.local"],
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

    pp2=<<-EOS
    f5_dns { '/Common/dns':
      name_servers         => ["4.1.1.1", "8.1.1.1"],
      search               => ["localhost1","f5.local1"],
    }
    EOS
    make_site_pp(pp2)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end

end
