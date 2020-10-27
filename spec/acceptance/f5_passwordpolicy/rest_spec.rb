require 'spec_helper_acceptance'

describe 'f5_passwordpolicy' do
  it 'sets password policy' do
    pp = <<-MANIFEST
    f5_passwordpolicy { '/Common/password-policy':
      expiration_warning => 10,
      max_duration       => 99998,
      max_login_failures => 0,
      min_duration       => 0,
      minimum_length     => 10,
      password_memory    => 0,
      policy_enforcement => true,
      required_lowercase => 2,
      required_numeric   => 1,
      required_special   => 1,
      required_uppercase => 1,
    }
    MANIFEST
    make_site_pp(pp)
    run_device(allow_changes: true)
    run_device(allow_changes: false)
  end
end
