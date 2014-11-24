require 'spec_helper_acceptance'

describe 'f5_monitor icmp provider' do
  it 'creates a basic monitor called my_icmp' do
    pp=<<-EOS
    f5_monitor { '/Common/my_icmp':
      ensure   => 'present',
      provider => 'icmp',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  it 'matches the default icmp monitor' do
    default_resource = run_resource('f5_monitor','/Common/icmp').sub(%r{/Common/icmp},'').sub(%r{parent_monitor => .*,}, "parent_monitor => 'redacted',")
    custom_resource  = run_resource('f5_monitor','/Common/my_icmp').sub(%r{/Common/my_icmp}, '').sub(%r{parent_monitor => .*,}, "parent_monitor => 'redacted',")
    expect(default_resource).to eq(custom_resource)
  end
  it 'inherits from parent providers' do
    pp=<<-EOS
    f5_monitor { '/Common/my_icmp1':
      ensure        => 'present',
      provider      => 'icmp',
      timeout       => '42',
    }
    -> f5_monitor { '/Common/my_icmp2':
      ensure        => 'present',
      provider      => 'icmp',
      parent_monitor => '/Common/my_icmp1',
    }
    EOS
    make_site_pp(pp)
    run_device()
    expect(run_resource('f5_monitor','/Common/my_icmp2')).to match(%r{42})
  end
  it 'works with transparent and reverse' do
    pp=<<-EOS
    f5_monitor { '/Common/icmp_transparent_reverse':
      ensure             => 'present',
      provider           => 'icmp',
      alias_address      => '10.10.10.8',
      alias_service_port => '80',
      receive_string     => 'foo',
      transparent        => 'enabled',
    }
    EOS
    make_site_pp(pp)
    run_device(:allow_changes => true)
    run_device(:allow_changes => false)
  end
  # Skipping T845090
end
