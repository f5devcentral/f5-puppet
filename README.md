#f5

####Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with f5](#setup)
    * [Beginning with f5](#beginning-with-f5)
4. [Usage - Configuration options and additional functionality](#usage)
	* [Set up two load-balanced web servers](#set-up-two-load-balanced-web-servers)
	* [Tips and Tricks](#tips-and-tricks)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

##Overview

The f5 module enables Puppet management of LTM F5 load balancers by providing types and REST-based providers. It supports F5 11.5+ and requires you to enable the REST endpoint.

##Module Description

This module uses REST to manage various aspects of F5 load balancers, and acts
as a foundation for building higher level abstractions within Puppet.

The module allows you to manage nodes, pools, in order to manage much of your F5 configuration through Puppet.

##Setup

###Beginning with f5

Before you can use the f5 module, you must create a proxy system able to run `puppet device`.  In order to do so, you will have a Puppet master and a Puppet agent as usual, and the agent will be the "proxy system" for the puppet device subcommand.

This means you must create a device.conf file in the Puppet conf directory (either /etc/puppet or /etc/puppetlabs/puppet) on the Puppet agent. Within your device.conf, you must have:

~~~
[bigip]
type f5
url https://<USERNAME>:<PASSWORD>@<IP ADDRESS OF BIGIP>/
~~~

In the above example, <USERNAME> and <PASSWORD> refer to Puppet's login for the device.

Additionally, you must install the faraday gem into the Puppet Ruby environment on the proxy host (Puppet agent). You can do this by declaring the `f5` class on that host. If you do not install the faraday gem, the module will not work.

##Usage

###Set up two load-balanced web servers.

####Before you begin

This example is built around the following pre-existing infrastructure: A server running a Puppet master is connected to the F5 device. The F5 device contains a management VLAN, a client VLAN which will contain the virtual server, and a server VLAN which will connect to the two web servers the module will be setting up.

In order to successfully set up your web servers, you must know the following information about your systems:

1. The IP addresses of both of the web servers;
2. The names of the nodes each web server will be on;
3. The ports the web servers are listening on; and
4. The IP address of the virtual server.

####Step One: Classifying your servers

In your site.pp file, enter the below code:

~~~
node bigip {
  f5_node { '/Common/WWW_Server_1':
    ensure                   => 'present',
    address                  => '172.16.226.10',
    description              => 'WWW Server 1',
    availability_requirement => 'all',
    health_monitors          => ['/Common/icmp'],
  }->
  f5_node { '/Common/WWW_Server_2':
    ensure                   => 'present',
    address                  => '172.16.226.11',
    description              => 'WWW Server 2',
    availability_requirement => 'all',
    health_monitors          => ['/Common/icmp'],
  }->
  f5_pool { '/Common/puppet_pool':
    ensure                    => 'present',
    members                   => [
      { name => '/Common/WWW_Server_1', port => '80', },
      { name => '/Common/WWW_Server_2', port => '80', },
    ],
    availability_requirement  => 'all',
    health_monitors           => ['/Common/http_head_f5'],
  }->
  f5_virtualserver { '/Common/puppet_vs':
    ensure                    => 'present',
    provider                  => 'standard',
    default_pool              => '/Common/puppet_pool',
    destination_address       => '192.168.80.100',
    destination_mask          => '255.255.255.255',
    http_profile              => '/Common/http',
    service_port              => '80',
    protocol                  => 'tcp',
    source                    => '0.0.0.0/0',
    vlan_and_tunnel_traffic   => {'enabled' => ['/Common/Client']},
  }
}
~~~

**The order of your resources is extremely important.** You must first establish your two web servers. In the code above, they are `f5_node { '/Common/WWW_Server_1'...` and `f5_node { '/Common/WWW_Server_2'...`. Each have the minimum number of parameters possible, and are set up with a health monitor that will ping each server directly to make sure it is still responsive. 

Then you establish the pool of servers. The pool is also set up with the minimum number of parameters. The health monitor for the pool will run an https request to see that a webpage is returned.

The virtual server brings your setup together. Your virtual server **must** have a `provider` assigned. 

####Step Two: Run puppet device

Run the following to have the device proxy node generate a certificate and apply your classifications to the F5 device.

~~~
$ puppet device -v --user=root
~~~

If you do not run this command, clients will not be able to make requests to the web servers.

At this point, your basic web servers should be up and fielding requests.

(Note: Due to [a bug](https://tickets.puppetlabs.com/browse/PUP-1391) passing `--user=root` is required, even though the command is already run as root.)

###Tips and Tricks

####Basic Usage

Once you've established a basic configuration, you can explore the providers and their allowed options by running `puppet resource <TYPENAME>` for each type. (**Note:** You must have your authentification credentials in `FACTER_url` within your command, or `puppet resource` will not work.) This will provide a starting point for seeing what's already on your F5. If anything failed to set up properly, it will not show up when you run the command.

To begin with you can simply call the types from the proxy system.

```
$ FACTER_url=https://<USERNAME>:<PASSWORD>@<IP ADDRESS OF BIGIP> puppet resource f5_node
```

To create, modify, or remove resources, they must be evaluated by `puppet
device` on a node that is contacting a puppet master.

####Role and Profiles
The [above example](#set-up-two-load-balanced-web-servers) is for setting up a simple configuration of two web servers. However, for anything more complicated, you will want to use the roles and profiles pattern when classifying nodes or devices for F5.

####Custom HTTP monitors
If you have a '/Common/http_monitor (which is available by default), then when you are creating a /Common/custom_http_monitor you can simply use `parent_monitor => '/Common/http'` so that you don't have to duplicate all values.

## Reference

####Notes 

* The defaults for any type's parameters are determined by your F5, which will vary based on your environment and version. Please consult [F5's documentation](https://support.f5.com/kb/en-us/products/big-ip_ltm.html) to discover the defaults pertinent to your setup.
* All resource type's titles are required to be in the format of /Partition/title, such as /Common/my_virtualserver.

###f5_node

Manages nodes on the F5 device. Go [here](https://support.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/ltm_configuration_guide_10_0_0/ltm_nodes.html#1172375) for information about configuring F5 nodes.

####Parameters:

####name

Specifies the name(s) of the node(s) resource(s) to manage.

Valid options: String

####address

Specifies the IP address of the node resource.

Valid options: 'ipv4' or 'ipv6'

####availability

Sets the number of health monitors that must be available. This **must** be set if you have any monitors, but cannot be set to more than the number of monitors you have.

Valid options: 'all' or integers

####connection_limit

Sets the maximum number of concurrent connections allowed for the virtual server. Setting this parameter to '0' will turn off connection limits.

Valid options: Integers

####connection_rate_limit

Sets the connection rate limit of the node.

Valid options: Integers

####description

Sets the description of the node.

Valid options: String

####ensure

Determines whether the node resource is present or absent.

Valid options: 'present' or 'absent'

####health_monitors

Assigns health monitor(s) to the node resource. You can assign a single monitor
or an array of monitors. If you're using an array of monitors then you must also set `availability`. 

Valid options: ["/PARTITION/OBJECTS"], 'default', or 'none'

####logging

Sets the logging state for the node resource.

Valid options: 'disabled', 'enabled', true, or false.

####provider

Specifies the backend to use for the `f5_node` resource. You will seldom need to specify this, as Puppet will usually discover the appropriate provider for your platform.

####ratio

Sets the ratio weight of the node resource. The number of connections that each machine receives over time is proportionate to a ratio weight you define for each machine within the pool.

Valid options: Integers

####state

Sets the state of the node resource.

Valid options: 'user-up' or 'user-down'


###f5_pool

Manages pools of `f5_node` resources on the F5 device. Go [here](https://support.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/ltm-concepts-11-1-0/ltm_pools.html) to learn more about F5 pools.

####Parameters:

####name

Specifies the name of the pool to manage.

Valid options: String

####allow_nat

Specifies whether to enable network address translations (NAT) for the pool.

Valid options: true or false

####allow_snat

Specifies whether to enable secure network address translations (SNAT) for the pool. 

Valid options: true or false

####availability

Sets the number of health monitors that must be available.  This **must** be set if you have any monitors, but cannot be set to more than the number of monitors you have.

Valid options: 'all' or integers

####description

Sets the description of the pool.

Valid options: String

####ensure

Determines whether the pool is present or absent.

Valid options: 'present' or 'absent'

####health_monitors

Sets health monitor(s) for the pool. You can assign a single monitor
or an array of monitors. If you're using an array of monitors then you must also set `availability`. 

Valid options: ["/PARTITION/OBJECTS"], 'default', or 'none'

####service_down

Specifies the action to take when the service is down.

Valid options: 'none', 'reject', 'drop', or 'reselect'

####slow_ramp_time

Sets the slow ramp time for the pool.

Valid options: Integers

####ip_tos_to_client

Sets the return packet ToS level for the pool. The value you set is inspected by upstream devices and will give outbound traffic the appropriate priority.

Valid options: 'pass-through', 'mimic', or an integer between 0 and 255

####ip_tos_to_server

Sets the packet ToS level for the pool. The BIG-IP system can apply an iRule and send the traffic to different pools of servers based on the ToS level you set.

Valid options: 'pass-through', 'mimic', or an integer between 0 and 255

####link_qos_to_client

Sets the return packet QoS level for the pool. The value you set will be inspected by upstream devices and will give outbound traffic the appropriate priority.

Valid options: 'pass-through' or an integer between 0 and 7

####link_qos_to_server

Sets the packet QoS level for the pool. The BIG-IP system can apply an iRule that sends the traffic to different pools of servers based on that QoS level you set.

Valid options: 'pass-through' or an integer between 0 and 7

####members

An array of hashes containing pool node members and their port. Pool members must exist on the F5 before you classify them in `f5_pool`. You can create the members using the `f5_node` type first. (See the example in [Usage](#usage).)

Valid options: 'none' or

    [
      {
        'name' => '/PARTITION/NODE NAME',
        'port' => <an integer between 0 and 65535>,
      },
      ...
    ]


####reselect_tries

Specifies the number of reselect tries to attempt.

Valid options: Integers

####request_queuing

Specifies whether to queue connection requests that exceed the connection capacity for the pool. (The connection capacity is determined by the `connection limit` set in `f5_node`.)

Valid options: true or false

####request_queue_depth

Specifies the maximum number of connection requests allowed in the queue. Defaults to '0', which allows unlimited connection requests constrained by available memory. This parameter can be set even if `request_queuing` is false, but it will not do anything until `request_queuing` is set to `true`.

Valid options: Integers

####request_queue_timeout

Specifies the maximum number of milliseconds that a connection request can be queued until capacity becomes available. If the connection is not made in the time specified, the connection request is removed from the queue and reset. Defaults to '0', which allows unlimited time in the queue. This parameter can be set even if `request_queuing` is false, but it will not do anything until `request_queuing` is set to `true`.

Valid options: Integers

####ip_encapsulation

Specifies the type of IP encapsulation on outbound packets, specifically BIG-IP system to server-pool member.

Valid options: '/PARTITION/gre', '/PARTITION/nvgre', '/PARTITION/dslite', '/PARTITION/ip4ip4', '/PARTITION/ip4ip6' '/PARTITION/ip6ip4', '/PARTITION/ip6ip6', or '/PARTITION/ipip'

####load_balancing_method

Sets the method of load balancing for the pool.

Valid options: 'round-robin', 'ratio-member', 'least-connections-member', 'observed-member', 'predictive-member', 'ratio-node', 'least-connection-node', 'fastest-node', 'observed-node', 'predictive-node', 'dynamic-ratio-member', 'weighted-least-connection-member', 'weighted-least-connection-node', 'ratio-session', 'ratio-least-connections-member', or 'ratio-least-connection-node'

####ignore_persisted_weight

Disables persisted weights in predictive load balancing methods. This parameter is only applicable when `load_balancing_method` is set to one of the following values: 'ratio-member', 'observed-member', 'predictive-member', 'ratio-node', 'observed-node', or 'predictive-node'.

Valid options: true or false

####priority_group_activation

Assigns `f5_node` resources to priority groups within the pool.

Valid options: 'disabled' or integers

###f5_irule

Creates and manages iRule objects on your F5 device. Go [here](https://devcentral.f5.com/articles/irules-101-01-introduction-to-irules) to learn more about iRules. 

####Parameters:

####definition

Set the syntax for your iRule. This parameter should be event declarations consisting of TCL code to be executed when an event occurs.

Valid options: Any valid iRule TCL script

####ensure

Determines whether iRules should be present on the F5 device.

Valid options: 'present' or 'absent'

####name

Sets the name of the iRule object. 

Valid options: String

####verify_signature

Verifies the signature contained in the `definition`.

Valid options: true or false 


###f5_monitor

Creates and Manages monitor objects, which determine the health or performance of pools, individual nodes, or virtual servers.  Go [here](https://support.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/ltm_configuration_guide_10_0_0/ltm_appendixa_monitor_types.html#1172375) to learn more about F5 monitors.

####Providers

**Note:** Not all features are available with all providers. The providers below were based on F5 monitor options you can read about [here](https://support.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/ltm-monitors-reference-11-1-0/3.html).
					
* `external` - Create your own monitor type. (Contains features: `external`.)
* `gateway_icmp` - Make a simple resource check using ICMP. (Contains features: `transparent`.)
* `http` - Check the status of HTTP traffic. (Contains features: `auth`, `dscp`, `reverse`, `strings`, and `transparent`.)
* `https` - Check the status of HTTPS traffic. (Contains features: `auth`, `dscp`, `reverse`, `ssl`, `strings`, and `transparent`.)
* `icmp` - Make a simple node check. (Contains features: `transparent`.)
* `ldap` - Check the status of LDAP servers. (Contains features: `auth`, `debug`, and `ldap`.)
* `sip` - Check the status of SIP Call-ID services. (Contains features: `debug` and `sip`.)
* `tcp` - Verify the TCP service by attempting to receive specific content from a resource.(Contains features: `dscp`, `reverse`, `strings`, and `transparent`.)
* `tcp_half` - Monitor a service by sending a TCP SYN packet to it. (Contains features: `transparent`.)
* `udp` - Verify the UDP service by attempting to send UDP packets to a pool, individual node, or virtual server. (Contains features: `debug`, `reverse`, `strings`, and `transparent`.)

####Features

**Note:** Not all features are available with all providers.

* `auth` - Enables authentication functionality. (Available with `http`, `https`, `ldap`. )
* `debug` - Enables debugging functionality. (Available with `ldap`, `sip`, and `udp`.)
* `dscp` - Enables DSCP functionality. (Available with `http`, `https`, and `tcp`.)
* `external` - Enables external command functionality. (Available with `external`.)
* `ldap` - Enables LDAP functionality. (Available with `ldap`.)
* `reverse` - Enables reverse test functionality. (Available with `http`, `https`, `tcp`, and `udp`.)
* `sip` - Enables SIP functionality. (Availlable with `sip`.)
* `ssl` - Enables SSL functionality. (Available with `https`.)
* `strings` - Enables you to send or receive strings. (Available with `http`, `https`, `tcp`, and `udp`.)
* `transparent` - Enables pass-through functionality. (Available with `gateway_icmp`, `http`, `https`, `icmp`, `tcp`, `tcp_half`, and `udp`.)


####Parameters

####additional_accepted_status_codes

Sets any additional accepted status codes for SIP monitors. (Requires `sip` feature.)

Valid options: '*', 'any', or an integer between 100 and 999

####additional_rejected_status_codes

Sets any additional rejected status codes for SIP monitors. (Requires `sip` feature.) 

Valid options: '*', 'any', or an integer between 100 and 999

####alias_address

Specifies the destination IP address for the monitor to check. 

Valid options: 'ipv4' or 'ipv6'

####alias_service_port

Specifies the destination port for the monitor to check.

Valid options: '*' or an integer between 1 and 65535

####arguments

Sets command arguments for an external monitor. (Requires `external` feature.)

Valid options: String

####base

Sets an LDAP base for the LDAP monitor. (Requires `ldap` feature.)

Valid options: String

####chase_referrals

Sets the LDAP chase referrals for the LDAP monitor. (Requires `ldap` feature.)

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'
 

####cipher_list

Specifies the list of ciphers that match either the ciphers of the client sending a request or those of the server sending a response. The ciphers in this parameter are what would be in the Cipher List field. (Requires `ssl` feature.)

Valid options: String

####client_certificate

Specifies the client certificate that the monitor sends to the target SSL server. (Requires `ssl` feature.)

Valid options: String

####client_key

Specifies a key for the client certificate that the monitor sends to the target SSL server. (Requires `ssl` feature.)

Valid options: String

####compatibility

Sets the SSL options setting in OpenSSL to 'ALL'. Defaults to 'enabled'.

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

####debug

Sets the debug option for LDAP, SIP, and UDP monitors. (Requires `debug` feature.)

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

####description 

Sets the description of the monitor.

Valid options: String

####ensure 

Determines whether or not the resource should be present.

Valid options: 'present' or 'absent'

####external_program

Specifies the command to run for an external monitor. (Requires `external` feature.)

Valid options: String

####filter

Sets the LDAP filter for the LDAP monitor. (Requires `ldap` feature.)

Valid options: String

####header_list

Specifies the headers for an SIP monitor. (Requires `sip` feature.)

Valid options: Array

####interval

Specifies how often to send a request. Determined in seconds. 

Valid options: Integers

####ip_dscp

Specifies the ToS or DSCP bits for optimizing traffic and allowing the appropriate TCP profiles to pass. Defaults to '0', which clears the ToS bits for all traffic using that profile. (Requires `dscp` feature.)

Valid options: An integer between 0 and 63

####mandatory_attributes

Specifies LDAP mandatory attributes for the LDAP monitor. (Requires `ldap` feature.)

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

####manual_resume

Enables the manual resume of a monitor, associates the monitor with a resource, disables the resource so it becomes unavailable, and leaves the resource offline until you manually re-enable it. 

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

####mode

Specifies the SIP mode for the SIP monitor. (Requires `sip` feature.)

Valid options: 'tcp', 'udp', 'tls', and 'sips'

####name 

Sets the name of the monitor. 

Valid options: String

####parent_monitor

Specifies the parent-predefined or user-defined monitor. **This parameter can't be modified once the monitor is created.** All providers can be used with this parameter.

Valid values: '/< PARTITION >/< MONITOR NAME >' (For example: '/Common/http_443')

####password

Sets the password for the monitor's authentication when checking a resource. (Requires `auth` feature.)

Valid options: String

####provider

Specifies the backend to use for the `f5_monitor` resource. You will seldom need to specify this, as Puppet will usually discover the appropriate provider for your platform.

Available providers can be found in the "Providers" section above.

####receive_string

Specifies the text string that the monitor looks for in the returned resource. (Requires `strings` feature.)

Valid options: Regular expression

####receive_disable_string

Specifies the text string the monitor looks for in the returned resource. (Requires `strings` feature.)

If you use a `receive_string` value together with a `receive_disable_string` value to match the value of a response from the origin web server, you can create one of three states for a pool member or node: Up (Enabled), when only `receive_string` matches the response; Up (Disabled), when only `receive_disable_string` matches the response; or Down, when neither `receive_string` nor `receive_disable_string` matches the response.

Valid options: Regular expression

####reverse

Marks the pool, pool member, or node down when the test is successful. (Requires `reverse` feature.)

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

####security

Sets the LDAP security for the LDAP monitor. (Requires `ldap` feature.)

Valid options: 'none', 'ssl', and 'tls'

####send_string

Specifies the text string that the monitor sends to the target resource. (Requires `strings` feature.)

Valid options: String For example: 'GET / HTTP/1.0\n\n'

####sip_request

Specifies the request to be sent by the SIP monitor. (Requires `sip` feature.)

Valid options: String

####time_until_up

Allows the system to delay the marking of a pool member or node as 'up' for some number of seconds after receipt of the first correct response.

Valid options: Integers

####timeout

Specifies the period of time to wait before timing out if a pool member or node being checked does not respond or the status of a node indicates that performance is degraded.

Valid options: Integers

####transparent

Enables you to specify the route through which the monitor pings the destination server, which forces the monitor to ping through the pool, pool member, or node with which it is associated (usually a firewall) to the pool, pool member, or node. (Requires `transparent` feature.)

Valid options:  'enabled', 'disabled', true, false, 'yes', or 'no'

####up_interval

Sets how often the monitor should check the health of a resource. 

Valid options: Integers, 'disabled', false, or 'no'

####username

Sets a username for the monitor's authentication when checking a resource. (Requires `auth` feature.)

Valid option: String

###f5_virtualserver

Creates and manages virtual node objects on your F5 device.

####Providers

**Note:** Not all features are available with all providers. The providers below were based on F5 virtual server options you can read about [here](https://support.f5.com/kb/en-us/solutions/public/14000/100/sol14163.html).

* **forwarding_ip** - Forwards packets directly to the destination IP address specified in the client request, and has no pool members to load balance. (Available with `bandwidth_control`, `clone_pool`,`connection_limit`, `connection_mirroring`, `irules`, `last_hop_pool`, `protocol_client`, `source_port`, `source_translation`, and `traffic_class`.)
* **forwarding_layer_2** - Shares the same IP address as a node in an associated VLAN group. (Available with `bandwidth_control`, `clone_pool`,`connection_limit`, `connection_mirroring`, `default_pool`, `fallback_persistence`, `irules`, `last_hop_pool`, `persistence`, `protocol_client`, `source_port`, `source_translation`, and `traffic_class`.)
* **performance_http** - Increases the speed at which the virtual server processes HTTP requests, and has a FastHTTP profile associated with it. (Available with `bandwidth_control`, `clone_pool`, `default_pool`, `irules`, `last_hop_pool`, `persistence`, `protocol_client`, `source_port`, `source_translation`, and `traffic_class`.)
* **performance_l4** - Increases the speed at which the virtual server processes packets, and has a FastL4 profile associated with it. (Available with `bandwidth_control`, `clone_pool`,`connection_limit`, `connection_mirroring`, `default_pool`, `fallback_persistence`, `irules`, `last_hop_pool`, `persistence`, `protocol_client`, `source_port`, `source_translation`, and `traffic_class`.)
* **reject** - Rejects any traffic destined for the virtual server IP address. (Available with `irules`, `source_port`, and `traffic_class`.)
* **standard** - Directs client traffic to a load balancing pool, and is a general purpose virtual server. (Available with `address_translation`, `bandwidth_control`, `clone_pool`,`connection_limit`, `connection_mirroring`, `default_pool`, `fallback_persistence`, `irules`, `persistence`, `policies`, `port_translation`, `protocol_client`, `protocol_server`, `source_port`, `source_translation`, `standard_profiles` and `traffic_class`.)
* **stateless** - Improves the performance of UDP traffic over a standard virtual server in specific scenarios but with limited feature support. (Available with `address_translation`, `connection_limit`, `default_pool`, `last_hop_pool`, and `port_translation`.)

####Features

**Note:** Not all features are available with all providers.

* **address_translation** - Supports address translation. (Available with `standard` and `stateless`.)
* **bandwidth_control** - Supports bandwidth control. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_http`, `performance_l4`, and `standard`.)
* **clone_pool** - Supports clone pools. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_http`, `performance_l4`, and `standard`.)
* **connection_limit** - Supports limiting connections. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_http`, `performance_l4`, `standard`, and `stateless`.)
* **connection_mirroring** - Supports mirroring connections. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_l4`, and `standard`.)
* **default_pool** - Supports setting a default pool. (Available with `forwarding_layer_2`, `performance_l4`, and `standard`.)
* **fallback_persistence** - Supports setting a fallback persistence profile. (Available with `forwarding_layer_2`, `performance_http`, `performance_l4`, `standard`, and `stateless`.)
* **irules** - Supports setting iRules. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_http`, `performance_l4`, `reject`, and `standard`.)
* **last_hop_pool** -  Supports a last hop pool. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_http`, `performance_l4`, and `stateless`.)
* **persistence** - Supports setting a persistence profile. (Available with `forwarding_layer_2`, `performance_http`, `performance_l4`, and `standard`.)
* **policies** - Supports policies. (Available with `standard`.)
* **port_translation** - Supports port translation. (Available with `standard` and `stateless`.)
* **protocol_client** - Supports client protocol profiles. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_http`, `performance_l4`, and `standard`.)
* **protocol_server** - Supports server protocol profiles. (Available with `standard`.)
* **source_port** - Supports source port setting. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_http`, `performance_l4`, `reject`, and `standard`.)
* **source_translation** - Supports source address translation. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_http`, `performance_l4`, and `standard`.)
* **standard_profiles** - Supports the standard set of profiles. (Available with `standard`.)
* **traffic_class** - Supports traffic class objects. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_http`, `performance_l4`, `reject`, and `standard`.)

####Parameters

####address_status

Determines whether the virtual server's IP should respond to pings based on pool member availability. 

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

####address_translation

Determines whether address translation is on or not. If the address is translated, the servers interpret the traffic as coming from the F5 and will respond to the F5. However, if the address is not translated, the servers interpret the traffic as coming from the router and will return the traffic there. Address translation only works at layer 4 and below. (Requires `address_translation` feature.)

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

####authentication_profiles

Enables you to use specific authentication profiles that make various traffic behaviors applicable to multiple protocols. The authentication profiles available when this parameter is enabled are: LDAP, RADIUS, TACACS+, SSL Client Certificate LDAP, SSL OCSP, and CRLDP. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####auto_last_hop

Allows the BIG-IP system to track the source MAC address of incoming connections and return traffic from pools to the source MAC address, regardless of the routing table. 

Valid options: 'default', 'enabled', or 'disabled'

####bandwidth_controller

Applies a bandwidth controller to enforce the total amount of bandwidth that can be used by the virtual server.  

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####clone_pool_client

Copies traffic to IDS's prior to address translation. 

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####clone_pool_server

Copies traffic to IDS's after address translation.

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####connection_limit

Sets the maximum number of concurrent connections allowed for the virtual server. Setting this to 0 turns off connection limits. (Requires `connection_limit` feature.)

Valid options: Integers

####connection_mirroring

Sets whether to mirror connection and persistence information to another device in order to prevent interruption in service during failover. (Requires `connection_mirroring` feature.)

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

####connection_rate_limit

Sets the connection rate limit of the object. 

Valid options: Integers or 'disabled'

####connection_rate_limit_destination_mas\

Specifies the CIDR mask of connection destinations with rate limiting.

Valid options: An integer between 0 and 32

####connection_rate_limit_mode

Sets the connection rate limit mode.

Valid options: 'per_virtual_server', 'per_virtual_server_and_source_address', 'per_virtual_server_and_destination_address', 'per_virtual_server_destination_and_source_address', 'per_source_address', 'per_destination_address', or 'per_source_and_destination_address'

####connection_rate_limit_source_mask

Specifies the CIDR mask of connection sources with rate limiting. 

Valid options: An integer between 0 and 32

####default_persistence_profile

Enables you to use specific persistence profiles that make various traffic behaviors applicable to multiple protocols. The persistence profiles available when this parameter is enabled are: Cookie, Destination Address Affinity, Hash, Microsoft Remote Desktop, SIP, Source Address Affinity, SSL, and Universal. (Requires `persistence` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####default_pool

Specifies a pool of nodes that F5 sends traffic to if not otherwise specified by another property such as an iRule or OneConnect profile. (Requires `default_pool` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####description

Sets the description of the virtual server.

Valid options: String

####destination_address

Sets the IP address of the virtual server.

Valid options: IP Address

####destination_mask

Specifies the netmask for a network virtual server, which clarifies whether the host is 0 or a wildcard representation. Is required for network virtual servers.

Valid options: Netmask

####diameter_profile 

Enables you to use a Diameter profile, which allows the BIG-IP system to send client-initiated Diameter messages to load balancing servers and ensure that those messages persist on the servers. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####dns_profile 

Enables you to use a custom DNS profile to enable features such as: converting IPv6-formatted addresses to IPv4 format, DNS Express, and DNSSEC. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####ensure

Determines whether or not the resource should be present.

Valid options: 'present' or 'absent'

####fallback_persistence_profile

Specifies the type of persistence that the BIG-IP system should use if it cannot use the default persistence. (Requires `fallback_persistence` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####fix_profile

Enables you to use Financial Information eXchange (FIX) protocol messages in routing, load balancing, persisting, and logging connections. (Requires `standard_profiles` feature.)  

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####ftp_profile 

Defines the behavior of File Transfer Protocol (FTP) traffic. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####html_profile

Enables the virtual server to modify HTML content that passes through it, according to your specifications. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####http_compression_profile

Enables compression of HTTP content to reduce the amount of data to be transmitted and significantly reduce bandwidth usage. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####http_profile

Enables you to use an HTTP profile which will ensure that HTTP traffic management suits your specific needs. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####irules

Enables the use of iRule objects on your virtual server. (Requires `irules` feature.)

Valid options: 'none' or '/< PARTITION >/< IRULE OBJECT NAME >'

####last_hop_pool

Directs reply traffic to the last hop router using a last hop pool. **Note: This parameter overrides the auto_lasthop setting.**

Valid options: 'none' or '/< PARTITION >/< POOL NAME >'

####name

Sets the name of the virtual server.

Valid options: String

####nat64

Maps IPv6 subscriber private addresses to IPv4 Internet public addresses. 

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

####ntlm_conn_pool

Enables use of an encrypted challenge/response protocol to authenticate a user without sending the user's password over the network. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####oneconnect_profile

Enables connection pooling on your virtual server. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####policies

Enables use of custom /Partition/Object policies.(Requires `policies` feature.)

Valid options: Array

####port_translation

Determines whether port translation is on or not. If the port is translated, the servers interpret the traffic as coming from the F5 and will respond to the F5. However, if the port is not translated, the servers interpret the traffic as coming from the router and will return the traffic there. (Requires `port_translation` feature.)

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

####protocol

Sets the network protocol name for which you want the virtual server to direct traffic. 

Valid options: 'all', 'tcp', 'udp', or 'sctp'

####protocol_profile_client

Enables you to use specific protocol profiles that expand the capacities of specific protocols pertaining to incoming connections from a web client. The protocol profiles available when this parameter is enabled are: Fast L4, Fast HTTP, HTTP Class, TCP, UDP, and SCTP. (Requires `protocol_client` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

Requires features protocol_client.

####protocol_profile_server

Enables you to use specific protocol profiles that expand the capacities of specific protocols pertaining to F5's connection to the virtual server's it's sending traffic to. The protocol profiles available when this parameter is enabled are: Fast L4, Fast HTTP, HTTP Class, TCP, UDP, and SCTP. (Requires `protocol_server` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####provider

Specifies the backend to use for the f5_virtualserver resource. You will seldom need to specify this, as Puppet will usually discover the appropriate provider for your platform.

Available providers can be found in the "Providers" section above.

####rate_class

Enables you to define the throughput limitations and packet scheduling method that you want the BIG-IP system to apply to all traffic that the rate class handles.

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####request_adapt_profile

Instructs an HTTP virtual server to send a request to a named virtual server of type Internal for possible modification by an Internet Content Adaptation Protocol (ICAP) server. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####request_logging_profile

Enables you to configure data within a log file for requests and responses in accordance with specified parameters. (Requires `standard_profiles` feature.) 

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####response_adapt_profile

Instructs an HTTP virtual server to send a response to a named virtual server of type Internal for possible modification by an Internet Content Adaptation Protocol (ICAP) server. (Requires `standard_profiles` feature.) 

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####rewrite_profile

Specifies the TCL expression that the system uses to rewrite the request URI that is forwarded to the server without sending an HTTP redirect to the client. **Note:** If you use static text rather than a TCL expression, the system will map the specified URI for every incoming request. (Requires `standard_profiles` feature.) 

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####rtsp_profile

Enables a client system to control a remote streaming-media server and allow time-based access to files on a server. (Requires `standard_profiles` feature.) 

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####service_port

Specifies a service name or port number for which you want to direct traffic. **This parameter is required.** (Requires `service_port` feature.)

Valid options: '*' or integers

####sip_profile

Configures how the virtual server handles SIP sessions. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####socks_profile

Configures the BIG-IP system to handle proxy requests and function as a gateway. Configuring browser traffic to use the proxy allows you to control whether to allow or deny a requested connection. (Requires `standard_profiles` feature.) 

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####source

Specifies the CIDR notation for traffic source address.

Valid options: '< IPADDRESS/ 0 - 32 >'. For instance: '78.0.0.0/8'.

####source_address_translation

Assigns an existing SNAT or LSN pool to the virtual server, or enables the Automap feature. When you use this setting, the BIG-IP system automatically maps all original source IP addresses passing through the virtual server to an address in the SNAT or LSN pool. (Requires `source_translation` feature.)

Valid options: 'automap', { 'snat' => '/Partition/pool_name'}, or { 'lsn' => '/Partition/pool_name'}

####source_port

Specifies whether the system preserves the source port of the connection. (Requires `source_port` feature.) 

Valid options: 'preserve', 'preserve_strict', or 'change'

####spdy_profile

Minimizes latency of HTTP requests by multiplexing streams and compressing headers. When you assign a SPDY profile to an HTTP virtual server, the HTTP virtual server informs clients that a SPDY virtual server is available to respond to SPDY requests. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####ssl_profile_client

Enables the the BIG-IP system to handle authentication and encryption tasks for any SSL connection coming into a BIG-IP system from a client system. (Requires `standard_profiles` feature.) 

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####ssl_profile_server

Enables the BIG-IP system to handle encryption tasks for any SSL connection being sent from a BIG-IP system to a target server. A server SSL profile is able to act as a client by presenting certificate credentials to a server when authentication of the BIG-IP system is required. (Requires `standard_profiles` feature.) 

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####state

Sets the state of the virtual server. 

Valid options: 'enabled', 'disabled', or 'forced_offline'

####statistics_profile

Provides user-defined statistical counters. 

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####stream_profile

Searches for and replaces strings within a data stream. (Requires `standard_profiles` feature.) 

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####traffic_class

Allows you to classify traffic according to a set of criteria that you define, such as source and destination IP addresses, for the virtual server. 

Valid options: An array of /Partition/traffic_class_name objects

####vlan_and_tunnel_traffic

Specifies the names of VLANs for which the virtual server is enabled or disabled.

Valid options: '< 'all','enabled', or 'disabled' > => [ '/Partition/object' ]}'

####vs_score

Weight taken into account by the Global Traffic Manager. 

Valid options: an integer between 0 and 100  (Note: value is a percentage.)

####web_acceleration_profile

Allows the BIG-IP system to store HTTP objects in memory and reuse these objects for subsequent connections. (Requires `standard_profiles` feature.) 

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

####xml_profile

Defines the formatting and attack pattern checks for the security policy. (Requires `standard_profiles` feature.) 

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##Limitations

F5: v11.5+.
Puppet Enterprise: v3.3+.

##Development

This is a proprietary module only available to Puppet Enterprise users.  As
such we have no formal way for users to contribute towards development.
However, we know our users are a charming collection of brilliant people and so
if you have a bug you've fixed or contribution to this module please just
generate a diff and throw it into a ticket to support and they'll ensure we get
it.

