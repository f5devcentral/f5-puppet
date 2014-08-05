require 'spec_helper'

describe Puppet::Type.type(:f5_monitor) do

  before :each do
    @node = Puppet::Type.type(:f5_monitor).new(:name => '/Common/testing')
  end

  {
    'interval'                         => { pass: %w(0 1 20 254 255), fail: %w(-1 true false enabled word 0.15)},
    'up_interval'                      => { pass: %w(disabled false 1 10 200 3000), fail: %w(yes please magic present superenabled) },
    'time_until_up'                    => { pass: %w(0 1 20 254 255), fail: %w(-1 true false enabled word 0.15)},
    'timeout'                          => { pass: %w(0 1 20 254 255), fail: %w(-1 true false enabled word 0.15)},
    'manual_resume'                    => { pass: %w(enabled disabled yes no true false), fail: %w(please magic present superenabled) },
    'compatibility'                    => { pass: %w(disabled enabled true false), fail: %w(1 2 3 4 5 yes no) },
    'reverse'                          => { pass: %w(enabled disabled yes no true false), fail: %w(please magic present superenabled) },
    'transparent'                      => { pass: %w(enabled disabled yes no true false), fail: %w(please magic present superenabled) },
    'alias_address'                    => { pass: %w(10.1.1.1 192.168.1.1 4.2.2.2 2001:cdba:0000:0000:0000:0000:3257:9652), fail: %w(-1 256 true false enabled word 0.15) },
    'alias_service_port'               => { pass: %w(* 1 10 20 65535), fail: %w(-1 65536 mimic true false enabled word 0.15) },
    'ip_dscp'                          => { pass: %w(0 10 200 3000), fail: %w(-1 mimic true false enabled word 0.15) },
    'debug'                            => { pass: %w(yes no true false), fail: %w(disabled enabled please magic present superenabled) },
    'security'                         => { pass: %w(none ssl tls), fail: %w(disabled enabled please magic present superenabled) },
    'mandatory_attributes'             => { pass: %w(yes no true false), fail: %w(disabled enabled please magic present superenabled) },
    'chase_referrals'                  => { pass: %w(yes no true false), fail: %w(disabled enabled please magic present superenabled) },
    'mode'                             => { pass: %w(tcp udp tls sips), fail: %w(disabled enabled please magic present superenabled) },
    'additional_accepted_status_codes' => { pass: %w(any none 20 300 400 5000), fail: %w(true false enabled word ) },
    'additional_rejected_status_codes' => { pass: %w(any none 20 300 400 5000), fail: %w(true false enabled word ) },
  }.each do |test, states|
    describe "#{test}" do
      states[:pass].each do |item|
        it "should allow #{test} to be set to #{item}" do
          @node[test.to_sym] = item
          # Special case the arrays we expect here.
          if ['additional_accepted_status_codes', 'additional_rejected_status_codes'].include?(test)
            expect(@node[test.to_sym]).to eq(Array(item))
          else
            expect(@node[test.to_sym].to_sym).to eq(item.to_sym)
          end
        end
      end

      states[:fail].each do |item|
        it "should fail when #{test} is set to #{item}" do
          expect { @node[test.to_sym] = item }.to raise_error()
        end
      end
    end
  end

end
