require 'spec_helper'

describe Puppet::Type.type(:f5_monitor) do

  before :each do
    @node = Puppet::Type.type(:f5_monitor).new(:name => '/Common/testing')
  end

  {
    'additional_accepted_status_codes' => { pass: %w(any none 20 300 400 5000), fail: %w(true false enabled word ) },
    'additional_rejected_status_codes' => { pass: %w(any none 20 300 400 5000), fail: %w(true false enabled word ) },
    'alias_address'                    => { pass: %w(10.1.1.1 192.168.1.1 4.2.2.2 2001:cdba:0000:0000:0000:0000:3257:9652), fail: %w(-1 256 true false enabled word 0.15) },
    'alias_service_port'               => { pass: %w(* 1 10 20 65535), fail: %w(-1 65536 mimic true false enabled word 0.15) },
    'chase_referrals'                  => { pass: %w(enabled disabled yes no true false), fail: %w(please magic present superenabled) },
    'compatibility'                    => { pass: %w(enabled disabled yes no true false), fail: %w(1 2 3 4 5) },
    'debug'                            => { pass: %w(enabled disabled yes no true false), fail: %w(please magic present superenabled) },
    'interval'                         => { pass: %w(0 1 20 254 255), fail: %w(-1 true false enabled word 0.15)},
    'ip_dscp'                          => { pass: %w(0 10 63), fail: %w(200 3000 -1 mimic true false enabled word 0.15) },
    'mandatory_attributes'             => { pass: %w(enabled disabled yes no true false), fail: %w(please magic present superenabled) },
    'manual_resume'                    => { pass: %w(enabled disabled yes no true false), fail: %w(please magic present superenabled) },
    'mode'                             => { pass: %w(tcp udp tls sips), fail: %w(disabled enabled please magic present superenabled) },
    'reverse'                          => { pass: %w(enabled disabled yes no true false), fail: %w(please magic present superenabled) },
    'security'                         => { pass: %w(none ssl tls), fail: %w(disabled enabled please magic present superenabled) },
    'time_until_up'                    => { pass: %w(0 1 20 254 255), fail: %w(-1 true false enabled word 0.15)},
    'timeout'                          => { pass: %w(0 1 20 254 255), fail: %w(-1 true false enabled word 0.15)},
    'transparent'                      => { pass: %w(enabled disabled yes no true false), fail: %w(please magic present superenabled) },
  }.each do |test, states|
    describe "#{test}" do
      states[:pass].each do |item|
        it "should allow #{test} to be set to #{item}" do
          @node[test.to_sym] = item
          # Special case the arrays we expect here.
          if [
            'additional_accepted_status_codes',
            'additional_rejected_status_codes',
          ].include?(test)
            expect(@node[test.to_sym]).to eq(Array(item))
          elsif [
            'chase_referrals',
            'compatibility',
            'debug',
            'mandatory_attributes',
            'manual_resume',
            'reverse',
            'transparent',
          ].include?(test)
            expect(@node[test.to_sym]).to match /(enabled|disabled|true|false|yes|no)/
          else
            expect(@node[test.to_sym].to_s.to_sym).to eq(item.to_s.to_sym)
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
  describe 'up_interval' do
    ['1','10','200','3000'].each do |item|
      it "should allow up_interval to be set to #{item}" do
        @node[:up_interval] = item
        expect(@node[:up_interval]).to eq(item.to_i)
      end
    end
    ['disabled','false','no','0'].each do |item|
      it "should allow up_interval to be set to #{item}" do
        @node[:up_interval] = item
        expect(@node[:up_interval]).to eq(0)
      end
    end
     %w(yes please magic present superenabled).each do |item|
       it "should fail when up_interval is set to #{item}" do
         expect { @node[:up_interval] = item }.to raise_error()
       end
     end
  end
end
