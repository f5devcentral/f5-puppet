require 'spec_helper_acceptance'

describe 'f5_irule' do
  it 'creates a basic irule called my_irule' do
    pp=<<-EOS
    f5_irule { '/Common/my_irule':
      ensure     => 'present',
      definition => 'when HTTP_REQUEST { HTTP::redirect https://[getfield [HTTP::host] ":" 1][HTTP::uri] }',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  it 'updates a basic irule called my_irule' do
    pp=<<-EOS
    f5_irule { '/Common/my_irule':
      ensure     => 'present',
      definition => 'when HTTP_REQUEST {
       HTTP::redirect https://[getfield [HTTP::host] ":" 1][HTTP::uri]
    }
definition-signature mwyl4XlRKRMQc0prWs7RtpgPcNfocOKb+MaFwAnQgAuUZZyG68OaGZsOCN3poUOFdHOc6fk2XAdGRmTRiP/7BCT7thsOX5zLFzA1N1wcr57KWVzEZt3ezxVXn2Z974OmbWm7P5Lclcr7N3adrLJMWfyfPPVF1tUYn0IQPD2QNMmfbcbr1oCuO93n/5dn0s6/EacHZGG53hVibW7xQuJXdMtoQ6ArSZ4U3n4vCDTb6NLYbAj6PirVzKY2pcsWFHFUSVrphSFwERc8+0XGHUE6Cb3ihzygoZc2cQ5jk3frFY70MkDluPTShFRbHd7PlMPRezrfkVZVeUHA/iBPcYcD+w==',
      verify_signature => true,
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  it 'deletes a irule' do
    pp=<<-EOS
    f5_irule { '/Common/my_irule':
      ensure   => 'absent',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
end
