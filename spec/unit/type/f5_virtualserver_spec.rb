require 'spec_helper'

describe Puppet::Type.type(:f5_virtualserver) do

  before :each do
    @node = Puppet::Type.type(:f5_virtualserver).new(:name => '/Common/testing', :http_profile => '/Common/profile')
  end

  {
    #'source'                                 => { pass: %w(192.168.1.1 10.1.1.1), fail: %w() },
    'destination'                            => { pass: [{'host' => '1.1.1.1', 'network' => '255.255.255.0'}],
                                                  fail: [{'host' => '1.1.1.1'}, {'network' => '255.255.255.0'}] },
    'service_port'                           => { pass: %w(* 1 10 100 1000 65535), fail: %w(0 65536 word) },
    'protocol_profile_server'                => { pass: %w(/Common/tcp), fail: %w(/Common/beep, tcp) },
    'http_profile'                           => { pass: %w(/Common/profile), fail: %w(profile) },
    'ftp_profile'                            => { pass: %w(/Common/profile), fail: %w(profile) },
    'rtsp_profile'                           => { pass: %w(/Common/profile), fail: %w(profile) },
    'socks_profile'                          => { pass: %w(/Common/profile), fail: %w(profile) },
    'xml_profile'                            => { pass: %w(/Common/profile), fail: %w(profile) },
    'stream_profile'                         => { pass: %w(/Common/profile), fail: %w(profile) },
    'ssl_profile_client'                     => { pass: %w(/Common/profile), fail: %w(profile) },
    'ssl_profile_server'                     => { pass: %w(/Common/profile), fail: %w(profile) },
    'authentication_profiles'                => { pass: %w(/Common/profile), fail: %w(profile) },
    'dns_profile'                            => { pass: %w(/Common/profile), fail: %w(profile) },
    'diameter_profile'                       => { pass: %w(/Common/profile), fail: %w(profile) },
    'fix_profile'                            => { pass: %w(/Common/profile), fail: %w(profile) },
    'request_adapt_profile'                  => { pass: %w(/Common/profile), fail: %w(profile) },
    'response_adapt_profile'                 => { pass: %w(/Common/profile), fail: %w(profile) },
    'sip_profile'                            => { pass: %w(/Common/profile), fail: %w(profile) },
    'statistics_profile'                     => { pass: %w(/Common/profile), fail: %w(profile) },
    'vlan_and_tunnel_traffic'                => {
      pass: [
        'all',
        {'enabled'  => ['/Partition/1']},
        {'disabled' => ['/Partition/1']},
        {'enabled'  => ['/Partition/1', '/Partition/2']},
        {'disabled' => ['/Partition/1', '/Partition/2']}
      ],
      fail: [
        'word',
        {'true'    => [ '/Partition/1' ]},
        {'enabled' => '/Partition/1'},
        {'enabled'  => ['1']},
      ]
    },
    #'source_address_translation'             => { pass: %w(), fail: %w() },
    #'bandwidth_controller'                   => { pass: %w(), fail: %w() },
    #'traffic_class'                          => { pass: %w(), fail: %w() },
    #'connection_rate_limit_mode'             => { pass: %w(), fail: %w() },
    #'connection_rate_limit_source_mask'      => { pass: %w(), fail: %w() },
    #'connection_rate_limit_destination_mask' => { pass: %w(), fail: %w() },
    #'source_port'                            => { pass: %w(), fail: %w() },
    #'clone_pool_client'                      => { pass: %w(), fail: %w() },
    #'clone_pool_server'                      => { pass: %w(), fail: %w() },
    #'auto_last_hop'                          => { pass: %w(), fail: %w() },
    #'last_hop_pool'                          => { pass: %w(), fail: %w() },
    #'analytics_profile'                      => { pass: %w(), fail: %w() },
    #'request_logging_profile'                => { pass: %w(), fail: %w() },
    #'vs_score'                               => { pass: %w(), fail: %w() },
    #'rewrite_profile'                        => { pass: %w(), fail: %w() },
    #'html_profile'                           => { pass: %w(), fail: %w() },
    #'rate_class'                             => { pass: %w(), fail: %w() },
    #'oneconnect_profile'                     => { pass: %w(), fail: %w() },
    #'ntlm_conn_pool'                         => { pass: %w(), fail: %w() },
    #'http_compression_profile'               => { pass: %w(), fail: %w() },
    #'web_acceleration_profile'               => { pass: %w(), fail: %w() },
    #'spdy_profile'                           => { pass: %w(), fail: %w() },
    #'irules'                                 => { pass: %w(), fail: %w() },
    #'policies'                               => { pass: %w(), fail: %w() },
    #'default_pool'                           => { pass: %w(), fail: %w() },
    #'default_persistence_profile'            => { pass: %w(), fail: %w() },
    #'fallback_persistence_profile'           => { pass: %w(), fail: %w() },
    #'address_translation'                    => { pass: %w(), fail: %w() },
    #'port_translation'                       => { pass: %w(), fail: %w() },
    #'nat64'                                  => { pass: %w(), fail: %w() },
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
            'address_translation',
            'port_translation',
            'nat64',
          ].include?(test)
            expect(@node[test.to_sym]).to match(/(enabled|disabled|true|false|yes|no)/)
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
end
