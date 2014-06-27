require 'spec_helper'

describe Puppet::Type.type(:f5_pool) do

  before :each do
    @node = Puppet::Type.type(:f5_pool).new(:name => '/Common/testing')
  end

  {
    'allow_nat'                 => { pass: %w(true false), fail: %w(disabled enabled yes please magic present superenabled) },
    'allow_snat'                => { pass: %w(true false), fail: %w(disabled enabled yes please magic present superenabled) },
    'service_down'              => { pass: %w(none reject drop reselect), fail: %w(true false 1 2 3 4 5 enabled) },
    'ip_tos_to_client'          => { pass: %w(pass-through mimic 0 1 20 254 255), fail: %w(-1 256 true false enabled word 0.15)},
    'ip_tos_to_server'          => { pass: %w(pass-through mimic 0 1 20 254 255), fail: %w(-1 256 true false enabled word 0.15) },
    'link_qos_to_client'        => { pass: %w(pass-through 0 1 2 3 4 5 6 7), fail: %w(-1 8 10 255 mimic true false enabled word 0.15) },
    'link_qos_to_server'        => { pass: %w(pass-through 0 1 2 3 4 5 6 7), fail: %w(-1 8 10 255 mimic true false enabled word 0.15) },
    'request_queue_depth'       => { pass: %w(1 20 300 400 5000), fail: %w(true false enabled word 0.15) },
    'request_queue_timeout'     => { pass: %w(1 20 300 400 5000), fail: %w(true false enabled word 0.15) },
    'reselect_tries'            => { pass: %w(0 1 20 300 400 5000 65535), fail: %w(-1 65536 true false enabled word 0.15) },
    'slow_ramp_time'            => { pass: %w(1 20 300 400 5000), fail: %w(true false enabled word 0.15) },
    'availability'              => { pass: %w(1 20 300 400 5000), fail: %w(true false enabled word 0.15) },
    'request_queuing'           => { pass: %w(true false), fail: %w(1 20 300 4000 enabled word 0.15)},
    'ip_encapsulation'          => { pass: %w(/Common/gre /Common/nvgre /Common/dslite /Common/ip4ip4 /Common/ip4ip6), fail: %w(gre nvgre dslite1 20 300 4000 enabled word 0.15) },
    'monitor'                   => { pass: %w(/Common/monitor /Common/http /Common/httpd none), fail: %w(gre nvgre dslite1 20 300 4000 enabled word 0.15) },
    'load_balancing_method'     => { pass: %w(round-robin predictive-member ratio-least-connection-node), fail: %w(round_robin true false 1 20 300 4000 enabled word 0.15) },
    'ignore_persisted_weight'   => { pass: %w(true false), fail: %w(1 20 300 4000 enabled word 0.15) },
    'priority_group_activation' => { pass: %w(1 20 300 400 5000 disabled), fail: %w(true false enabled word 0.15) },
  }.each do |test, states|
    describe "#{test}" do
      states[:pass].each do |item|
        it "should allow #{test} to be set to #{item}" do
          @node[test.to_sym] = item
          # Special case the arrays we expect here.
          if test == 'monitor'
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

  describe 'global validation' do
    it 'should fail if availability count > monitors' do
      expect { Puppet::Type.type(:f5_pool).new(
          :name         => '/Common/testing',
          :monitor      => ['/Common/monitor'],
          :availability => '2')
      }.to raise_error(/Availability count cannot be more than the total number of monitors./)
    end

    it 'should fail if monitor is an array and no availability set' do
      expect { Puppet::Type.type(:f5_pool).new(
          :name    => '/Common/testing',
          :monitor => ['/Common/monitor'])
      }.to raise_error(/Availability must be set when monitors are assigned./)
    end

    it 'should fail if monitor is a string and availability set' do
      expect { Puppet::Type.type(:f5_pool).new(
          :name         => '/Common/testing',
          :availability => '2',)
      }.to raise_error(/Availability cannot be set when no monitor is assigned./)
    end
  end

end
