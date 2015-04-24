require 'spec_helper_acceptance'

describe 'something' do
  it 'makes a node' do
    pp=<<-EOS
     f5_node { '/Common/my_testnode':
       ensure      => 'present',
       address     => '192.168.98.98',
       description => 'My F5 test node',
     }
    EOS
    make_site_pp(pp)
    run_device()
  end
end
