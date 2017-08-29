require 'spec_helper_acceptance'

describe 'f5_license' do

  it 'execute tmsh command' do
    pp=<<-EOS
    f5_license { '/Common/license':
      registration_key => "GKWPN-NDMLV-CXSTE-NWDEX-PCFPTLV"
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)

  end

end
