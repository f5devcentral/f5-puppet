# f5

#### Table of Contents

1. [Overview](#overview)
2. [Warning](#warning)
3. [Module Description - What the module does and why it is useful](#module-description)
4. [Setup - The basics of getting started with f5](#setup)
    * [Beginning with f5](#beginning-with-f5)
5. [Usage - Configuration options and additional functionality](#usage)
	* [Set up two load-balanced web servers](#set-up-two-load-balanced-web-servers)
	* [Tips and Tricks](#tips-and-tricks)
6. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
7. [Limitations - OS compatibility, etc.](#limitations)
8. [Development - Guide for contributing to the module](#development)
9. [Support](#support)

## Overview

The f5 module enables Puppet management of LTM F5 load balancers by providing types and REST-based providers.  The Puppet, Inc. versions (<= v1.5.4) of this module are no longer in development.  That module has been merged with the development efforts of F5.  Starting with v1.6.0, BIG-IP module development will be handled by F5.

## Warning

Per the information in the [Overview](#overview), this module cannot be used in conjunction with the former, deprecated module under the namespace of [puppetlabs/f5](https://forge.puppet.com/puppetlabs/f5).  The [puppetlabs/f5](https://forge.puppet.com/puppetlabs/f5) module must be removed before you installing this module.  This is recommended as this module will be the only actively maintained module in the future.

## Module Description

This module uses REST to manage various aspects of F5 load balancers, and acts
as a foundation for building higher level abstractions within Puppet.

The module allows you to manage nodes, pools, applications, and application service, in order to manage much of your F5 configuration through Puppet.

## Setup

### Beginning with f5

Before you can use the f5 module, you must create a proxy system able to run `puppet device`. Your Puppet agent will serve as the "proxy system" for the `puppet device` subcommand.

Create a device.conf file in the Puppet conf directory (either /etc/puppet or /etc/puppetlabs/puppet) on the Puppet agent. Within your device.conf, you must have:

~~~
[bigip]
type f5
url https://<USERNAME>:<PASSWORD>@<IP ADDRESS OF BIGIP>/
~~~

In the above example, `<USERNAME>` and `<PASSWORD>` refer to Puppet's login for the device.

Additionally, you must install the faraday gem into the Puppet Ruby environment on the proxy host (Puppet agent) by declaring the `f5` class on that host. If you do not install the faraday gem, the module will not work.

## Usage example

### Set up two load-balanced web servers.

#### Before you begin

This example assumes the following pre-existing infrastructure:

1. A server running as a Puppet master.
2. A Puppet agent running as a proxy or controller to the f5 device.
3. A f5 device that has been registered with the Puppet master via the proxy or controller.

The F5 device contains a management VLAN, a client VLAN to contain the virtual server, and a server VLAN to connect to the two web servers the module sets up.

To load balance requests between 2 webservers using the BIG-IP, you must know the following information about your systems:

1. The IP addresses of both of the web servers;
2. The names of the nodes each web server will be on;
3. The ports the web servers are listening on; and
4. The IP address of the virtual server.

### Steps

1.  Classify the f5 device with the required resource types.
2.  Apply classification to the device from the proxy or controller by running `puppet device -v --user=root`.

See below for the detailed steps.

#### Step One: Classifying your servers

In your site.pp, `<devicecertname>.pp` node manifest, or a `profiles::<profile_name>` manifest file, enter the below code in the relevant class statement or node declaration:

~~~puppet
  f5_node { '/Common/WWW_Server_1':
    ensure                   => 'present',
    address                  => '172.16.226.10',
    description              => 'WWW Server 1',
    availability_requirement => 'all',
    health_monitors          => ['/Common/icmp'],
  }
  f5_node { '/Common/WWW_Server_2':
    ensure                   => 'present',
    address                  => '172.16.226.11',
    description              => 'WWW Server 2',
    availability_requirement => 'all',
    health_monitors          => ['/Common/icmp'],
  }
  f5_pool { '/Common/puppet_pool':
    ensure                    => 'present',
    members                   => [
      { name => '/Common/WWW_Server_1', port => '80', },
      { name => '/Common/WWW_Server_2', port => '80', },
    ],
    availability_requirement  => 'all',
    health_monitors           => ['/Common/http_head_f5'],
    require                   => [
      F5_node['/Common/WWW_Server_1'],
      F5_node['/Common/WWW_Server_2'],
    ],
  }
  f5_virtualserver { '/Common/puppet_vs':
    ensure                     => 'present',
    provider                   => 'standard',
    default_pool               => '/Common/puppet_pool',
    destination_address        => '192.168.80.100',
    destination_mask           => '255.255.255.255',
    http_profile               => '/Common/http',
    service_port               => '80',
    protocol                   => 'tcp',
    source_address_translation => 'automap',
    source                     => '0.0.0.0/0',
    vlan_and_tunnel_traffic    => {'enabled' => ['/Common/Client']},
    require                    => F5_pool['/Common/puppet_pool'],
  }
~~~

**The order of your resources is extremely important.** You must first establish your two web servers. In the code above, they are `f5_node { '/Common/WWW_Server_1'...` and `f5_node { '/Common/WWW_Server_2'...`. Each has the minimum number of parameters possible and is set up with a health monitor that pings each server directly to make sure it is still responsive.

Next, establish the pool of servers. The pool is also set up with the minimum number of parameters. The health monitor for the pool runs an https request to see that a webpage is returned.

Finally, the virtual server brings your setup together. Your virtual server **must** have a `provider` assigned.

If you're using a profile, remember to apply the profile to the node with either the console, your ENC, or site.pp.

#### Step Two: Run puppet device

Run the following command to have the device proxy node generate a certificate and apply your classifications to the F5 device.

~~~
$ puppet device -v --user=root
~~~

If you do not run this command, clients can not make requests to the web servers.

At this point, your basic web servers should be up and fielding requests.

(Note: Due to [a bug](https://tickets.puppetlabs.com/browse/PUP-1391), passing `--user=root` is required, even though the command is already run as root.)

### Tips and Tricks

#### Basic usage

Once you've established a basic configuration, you can explore the providers and their allowed options by running `puppet resource <TYPENAME>` for each type. (**Note:** You must have your authentification credentials in `FACTER_url` within your command, or `puppet resource` will not work.) This provides a starting point for seeing what's already on your F5. If anything failed to set up properly, it will not show up when you run the command.

To begin with, call the types from the proxy system.

~~~
$ FACTER_url=https://<USERNAME>:<PASSWORD>@<IP ADDRESS OF BIGIP> puppet resource f5_node
~~~

To manage the device (create, modify, or remove resources), classify the bigip
just as you would classify any other Puppet node (site.pp, ENC,
Console, etc.), using the device certname specified in device.conf.
Then run `puppet device -v` on the proxy node as you would normally use the
`puppet agent` command.

#### Role and profiles

The [above example](#set-up-two-load-balanced-web-servers) is for setting up a simple configuration of two web servers. However, for anything more complicated, use the roles and profiles pattern when classifying nodes or devices for F5.

#### Custom HTTP monitors

If you have a '/Common/http_monitor' (which is available by default), then when you are creating a '/Common/custom_http_monitor' you can use just `parent_monitor => '/Common/http'`, so that you don't have to duplicate all values.

## Reference

#### Notes

* The defaults for any given type's parameters are determined by your F5, which varies based on your environment and version. Please consult [F5's documentation](https://support.f5.com/kb/en-us/products/big-ip_ltm.html) to discover the defaults pertinent to your setup.
* All resource type titles are required to be in the format of `/Partition/title`, such as `/Common/my_virtualserver`.

### Private Classes

* [f5]: The main class of the module. Installs the faraday gem; contains no adjustable settings.

### Types

* [f5_iapp](#f5_iapp): Manages iApp instances on the F5 device.
* [f5_node](#f5_node): Manages nodes on the F5 device.
* [f5_pool](#f5_pool): Manages pools of `f5_node` resources on the F5 device.
* [f5_irule](#f5_irule): Creates and manages iRule objects on your F5 device.
* [f5_monitor](#f5_monitor): Creates and manages monitor objects, which determine the health or performance of pools, individual nodes, or virtual servers.
* [f5_virtualserver](#f5_virtualserver): Creates and manages virtual node objects on your F5 device.
* [f5_partition](#f5_partition): Manages partitions on the F5 device.
* [f5_vlan](#f5_vlan): Manages virtual LANs on the F5 device.
* [f5_selfip](#f5_selfip): Sets the self IP address on the BIG-IP system.
* [f5_dns](#f5_dns): Sets the system DNS on the BIG-IP system.
* [f5_ntp](#f5_ntp): Sets the system NTP on the BIG-IP system.
* [f5_globalsetting](#f5_globalsetting): Sets the gener system global setting on the BIG-IP system.
* [f5_user](#f5_user): Sets the user account on the BIG-IP system.
* [f5_route](#f5_route): Configure route on the Big-IP system.
* [f5_root](#f5_root): Modify the password of the root user on the Big-IP system.
* [f5_license](#f5_license): Manage license installation and activation on BIG-IP devices
* [f5_selfdevice](#f5_selfdevice): Change device name from default bigip1
* [f5_device](#f5_device): Manages device IP configuration settings for HA on a BIG-IP.
* [f5_addtotrust](#f5_addtotrust): Manage the trust relationships between BIG-IPs.
* [f5_devicegroup](#f5_devicegroup): Manage device groups on a BIG-IP.
* [f5_configsync](#f5_configsync): Perform initial sync of the Device Group.
* [f5_command](#f5_command): Run arbitrary TMSH command on the Big-IP system.
* [f5_persistencecookie](#f5_persistencecookie): Manage Virtual server Cookie persistence profile on a BIG-IP
* [f5_persistencedestaddr](#f5_persistencedestaddr): Manage Virtual server Destination Address Affinity persistence profile on a BIG-IP
* [f5_persistencehash](#f5_persistencehash): Manage Virtual server Hash persistence profile on a BIG-IP
* [f5_persistencesourceaddr](#f5_persistencesourceaddr): Manage Virtual server Source Address persistence profile on a BIG-IP
* [f5_persistencessl](#f5_persistencessl): Manaage Virtual server SSL persistence profile on a BIG-IP
* [f5_persistenceuniversal](#f5_persistenceuniversal): Manage Virtual server Universal persistence profile on a BIG-IP
* [f5_profilehttp](#f5_profilehttp): Manage Virtual server HTTP traffic profile
* [f5_profileclientssl](#f5_profileclientssl): Manage Virtual server client-side proxy SSL profile
* [f5_profileserverssl](#f5_profileserverssl): Manage Virtual server server-side proxy SSL profile
* [f5_sslkey](#f5_sslkey): Import SSL keys from BIG-IP
* [f5_sslcertificate](#f5_sslcertificate): Import SSL certificate from BIG-IP
* [f5_snat](#f5_snat): Manage Secure network address translation (SNAT)
* [f5_snatpool](#f5_snatpool): Manage SNAT pools on a BIG-IP
* [f5_datagroup](#f5_datagroup): Manage Internal data group
* [f5_datagroupexternal](#f5_datagroupexternal): Manage External data group


### Type: f5_iapp

Manage iApp application services on the F5 device. See [F5 documentation](https://devcentral.f5.com/s/articles/getting-started-with-iapps-a-conceptual-overview-20524) for information about iApps. The best way to get started is to create an application service in the F5 gui, then copy the manifest returned for it via `puppet resource f5_iapp`

#### Parameters

##### name
Specifies the name of the iApp application service to manage. Must be in the form of `/<partition/<instance name>.app/<instance name>` . Example: `/Common/my_test.app/my_test`

Valid options: a string.

##### template
Name of the iApp template to be used when creating the iApp application service.

Valid options: a string.

##### variables
Hash containing iApp vars for the given template.

Valid options: a hash.

##### tables
Hash containing iApp table entries for the given template.

Valid options: a hash.

### Type: f5_node

Manages nodes on the F5 device. See [F5 documentation](https://techdocs.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/ltm-concepts-11-5-1/5.html) for information about configuring F5 nodes.

#### Parameters

##### name

Specifies the name of the node resource to manage.

Valid options: a string.

##### address

Specifies the IP address and route domain ID of the node resource.

Valid options: IPv4 or IPv6 addresses optionally followed by % sign and a route domain ID, such as '10.0.5.5%3'.

##### availability_requirement

Sets the number of health monitors that must be available. This **must** be set if you have any monitors, but it cannot be set to more than the number of monitors you have.

Valid options: 'all' or an integer.

##### connection_limit

Sets the maximum number of concurrent connections allowed for the virtual server. Setting this parameter to '0' turns off connection limits.

Valid options: an integer.

##### connection_rate_limit

Sets the connection rate limit of the node.

Valid options: an integer.

##### description

Sets the description of the node.

Valid options: a string.

##### ensure

Determines whether the node resource is present or absent.

Valid options: 'present' or 'absent'.

##### health_monitors

Assigns health monitors to the node resource. You can assign a single monitor
or an array of monitors. If you're using an array of monitors then you must also set `availability_requirement`.

Valid options: ["/PARTITION/OBJECTS"], 'default', or 'none'

##### logging

Sets the logging state for the node resource.

Valid options: 'disabled', 'enabled', true, or false.

##### provider

Specifies the backend to use for the `f5_node` resource. You seldom need to specify this, as Puppet usually discovers the appropriate provider for your platform.

##### ratio

Sets the ratio weight of the node resource. The number of connections that each machine receives over time is proportionate to a ratio weight you define for each machine within the pool.

Valid options: an integer.

##### state

Sets the state of the node resource.

Valid options: 'enabled', 'disabled' or 'forced_offline'


### f5_pool

Manages pools of `f5_node` resources on the F5 device. See [F5 documentation](https://techdocs.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/ltm-concepts-11-5-0/5.html) to learn more about F5 pools.

#### Parameters

##### name

Specifies the name of the pool to manage.

Valid options: a string.

##### allow_nat

Specifies whether to enable network address translations (NAT) for the pool.

Valid options: true or false

##### allow_snat

Specifies whether to enable secure network address translations (SNAT) for the pool.

Valid options: true or false

##### availability_requirement

Sets the number of health monitors that must be available.  This **must** be set if you have any monitors, but cannot be set to more than the number of monitors you have.

Valid options: 'all' or integers

##### description

Sets the description of the pool.

Valid options: a string.

##### ensure

Determines whether the pool is present or absent.

Valid options: 'present' or 'absent'

##### health_monitors

Sets the health monitor for the pool. You can assign a single monitor
or an array of monitors. If you're using an array of monitors then you must also set `availability_requirement`.

Valid options: ["/PARTITION/OBJECTS"], 'default', or 'none'

##### service_down

Specifies the action to take when the service is down.

Valid options: 'none', 'reject', 'drop', or 'reselect'

##### slow_ramp_time

Sets the slow ramp time for the pool.

Valid options: an integer.

##### ip_tos_to_client

Sets the return packet ToS level for the pool. The value you set is inspected by upstream devices and gives outbound traffic the appropriate priority.

Valid options: 'pass-through', 'mimic', or an integer between 0 and 255

##### ip_tos_to_server

Sets the packet ToS level for the pool. The BIG-IP system can apply an iRule and send the traffic to different pools of servers based on the ToS level you set.

Valid options: 'pass-through', 'mimic', or an integer between 0 and 255

##### link_qos_to_client

Sets the return packet QoS level for the pool. The value you set is inspected by upstream devices and gives outbound traffic the appropriate priority.

Valid options: 'pass-through' or an integer between 0 and 7

##### link_qos_to_server

Sets the packet QoS level for the pool. The BIG-IP system can apply an iRule that sends the traffic to different pools of servers based on that QoS level you set.

Valid options: 'pass-through' or an integer between 0 and 7

##### members

An array of hashes containing pool node members and their port. Pool members must exist on the F5 before you classify them in `f5_pool`. You can create the members using the `f5_node` type first. (See the example in [Usage](#usage).)

Valid options: 'none' or

    [
      {
        'name' => '/PARTITION/NODE NAME',
        'port' => <an integer between 0 and 65535>,
      },
      ...
    ]


##### reselect_tries

Specifies the number of reselect tries to attempt.

Valid options: an integer.

##### request_queuing

Specifies whether to queue connection requests that exceed the connection capacity for the pool. (The connection capacity is determined by the `connection limit` set in `f5_node`.)

Valid options: true or false.

##### request_queue_depth

Specifies the maximum number of connection requests allowed in the queue. Defaults to '0', which allows unlimited connection requests constrained by available memory. This parameter can be set even if `request_queuing` is false, but it does not do anything until `request_queuing` is set to `true`.

Valid options: an integer.

##### request_queue_timeout

Specifies the maximum number of milliseconds that a connection request can be queued until capacity becomes available. If the connection is not made in the time specified, the connection request is removed from the queue and reset. Defaults to '0', which allows unlimited time in the queue. This parameter can be set even if `request_queuing` is false, but it does not do anything until `request_queuing` is set to `true`.

Valid options: an integer.

##### ip_encapsulation

Specifies the type of IP encapsulation on outbound packets, specifically BIG-IP system to server-pool member.

Valid options: '/PARTITION/gre', '/PARTITION/nvgre', '/PARTITION/dslite', '/PARTITION/ip4ip4', '/PARTITION/ip4ip6' '/PARTITION/ip6ip4', '/PARTITION/ip6ip6', or '/PARTITION/ipip'.

##### load_balancing_method

Sets the method of load balancing for the pool.

Valid options: 'round-robin', 'ratio-member', 'least-connections-member', 'observed-member', 'predictive-member', 'ratio-node', 'least-connection-node', 'fastest-node', 'observed-node', 'predictive-node', 'dynamic-ratio-member', 'weighted-least-connection-member', 'weighted-least-connection-node', 'ratio-session', 'ratio-least-connections-member', or 'ratio-least-connection-node'

##### ignore_persisted_weight

Disables persisted weights in predictive load balancing methods. This parameter is only applicable when `load_balancing_method` is set to one of the following values: 'ratio-member', 'observed-member', 'predictive-member', 'ratio-node', 'observed-node', or 'predictive-node'.

Valid options: true or false

##### priority_group_activation

Assigns `f5_node` resources to priority groups within the pool.

Valid options: 'disabled' or integers

### f5_irule

Creates and manages iRule objects on your F5 device. See [F5 documentation](https://techdocs.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/ltm-concepts-11-5-0/18.html) to learn more about iRules.

#### Parameters

##### definition

Set the syntax for your iRule. This parameter should be event declarations consisting of TCL code to be executed when an event occurs.

Valid options: Any valid iRule TCL script

##### ensure

Determines whether iRules should be present on the F5 device.

Valid options: 'present' or 'absent'

##### name

Sets the name of the iRule object.

Valid options: a string.

##### verify_signature

Verifies the signature contained in the `definition`.

Valid options: true or false

### f5_monitor

Creates and manages monitor objects, which determine the health or performance of pools, individual nodes, or virtual servers. See [F5 documentation](https://techdocs.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/ltm-concepts-11-5-0/14.html) to learn more about F5 monitors.

#### Providers

**Note:** Not all features are available with all providers. The providers below are based on [F5 monitor options](https://support.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/ltm-monitors-reference-11-1-0/3.html).

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

#### Features

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


#### Parameters

##### additional_accepted_status_codes

Sets any additional accepted status codes for SIP monitors. (Requires `sip` feature.)

Valid options: '*', 'any', or an integer between 100 and 999

##### additional_rejected_status_codes

Sets any additional rejected status codes for SIP monitors. (Requires `sip` feature.)

Valid options: '*', 'any', or an integer between 100 and 999

##### alias_address

Specifies the destination IP address for the monitor to check.

Valid options: 'ipv4' or 'ipv6'

##### alias_service_port

Specifies the destination port for the monitor to check.

Valid options: '*' or an integer between 1 and 65535

##### arguments

Sets command arguments for an external monitor. (Requires `external` feature.)

Valid options: a string.

##### base

Sets an LDAP base for the LDAP monitor. (Requires `ldap` feature.)

Valid options: a string.

##### chase_referrals

Sets the LDAP chase referrals for the LDAP monitor. (Requires `ldap` feature.)

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

##### cipher_list

Specifies the list of ciphers that match either the ciphers of the client sending a request or those of the server sending a response. The ciphers in this parameter are what would be in the Cipher List field. (Requires `ssl` feature.)

Valid options: a string.

##### client_certificate

Specifies the client certificate that the monitor sends to the target SSL server. (Requires `ssl` feature.)

Valid options: a string.

##### client_key

Specifies a key for the client certificate that the monitor sends to the target SSL server. (Requires `ssl` feature.)

Valid options: a string.

##### compatibility

Sets the SSL options setting in OpenSSL to 'ALL'. Defaults to 'enabled'.

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

##### debug

Sets the debug option for LDAP, SIP, and UDP monitors. (Requires `debug` feature.)

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

##### description

Sets the description of the monitor.

Valid options: a string.

##### ensure

Determines whether or not the resource should be present.

Valid options: 'present' or 'absent'

##### external_program

Specifies the command to run for an external monitor. (Requires `external` feature.)

Valid options: a string.

##### filter

Sets the LDAP filter for the LDAP monitor. (Requires `ldap` feature.)

Valid options: a string.

##### header_list

Specifies the headers for an SIP monitor. (Requires `sip` feature.)

Valid options: Array

##### interval

Specifies how often to send a request. Determined in seconds.

Valid options: an integer.

##### ip_dscp

Specifies the ToS or DSCP bits for optimizing traffic and allowing the appropriate TCP profiles to pass. Defaults to '0', which clears the ToS bits for all traffic using that profile. (Requires `dscp` feature.)

Valid options: An integer between 0 and 63

##### mandatory_attributes

Specifies LDAP mandatory attributes for the LDAP monitor. (Requires `ldap` feature.)

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

##### manual_resume

Enables the manual resume of a monitor, associates the monitor with a resource, disables the resource so it becomes unavailable, and leaves the resource offline until you manually re-enable it.

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

##### mode

Specifies the SIP mode for the SIP monitor. (Requires `sip` feature.)

Valid options: 'tcp', 'udp', 'tls', and 'sips'

##### name

Sets the name of the monitor.

Valid options: a string.

##### parent_monitor

Specifies the parent-predefined or user-defined monitor. **This parameter can't be modified once the monitor is created.** All providers can be used with this parameter.

Valid values: '/< PARTITION >/< MONITOR NAME >' (For example: '/Common/http_443')

##### password

Sets the password for the monitor's authentication when checking a resource. (Requires `auth` feature.)

Valid options: a string.

##### provider

Specifies the backend to use for the `f5_monitor` resource. You seldom need to specify this, as Puppet usually discovers the appropriate provider for your platform.

Available providers can be found in the "Providers" section above.

##### receive_string

Specifies the text string that the monitor looks for in the returned resource. (Requires `strings` feature.)

Valid options: Regular expression

##### receive_disable_string

Specifies the text string the monitor looks for in the returned resource. (Requires `strings` feature.)

If you use a `receive_string` value together with a `receive_disable_string` value to match the value of a response from the origin web server, you can create one of three states for a pool member or node: Up (Enabled), when only `receive_string` matches the response; Up (Disabled), when only `receive_disable_string` matches the response; or Down, when neither `receive_string` nor `receive_disable_string` matches the response.

Valid options: Regular expression

##### reverse

Marks the pool, pool member, or node down when the test is successful. (Requires `reverse` feature.)

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

##### security

Sets the LDAP security for the LDAP monitor. (Requires `ldap` feature.)

Valid options: 'none', 'ssl', and 'tls'

##### send_string

Specifies the text string that the monitor sends to the target resource. (Requires `strings` feature.)

Valid options: a string; for example: 'GET / HTTP/1.0\n\n'.

##### sip_request

Specifies the request to be sent by the SIP monitor. (Requires `sip` feature.)

Valid options: a string.

##### time_until_up

Allows the system to delay the marking of a pool member or node as 'up' for some number of seconds after receipt of the first correct response.

Valid options: an integer.

##### timeout

Specifies the period of time to wait before timing out if a pool member or node being checked does not respond or the status of a node indicates that performance is degraded.

Valid options: an integer.

##### transparent

Enables you to specify the route through which the monitor pings the destination server, which forces the monitor to ping through the pool, pool member, or node with which it is associated (usually a firewall) to the pool, pool member, or node. (Requires `transparent` feature.)

Valid options:  'enabled', 'disabled', true, false, 'yes', or 'no'

##### up_interval

Sets how often the monitor should check the health of a resource.

Valid options: an integer, 'disabled', false, or 'no'

##### username

Sets a username for the monitor's authentication when checking a resource. (Requires `auth` feature.)

Valid option: a string.

### f5_virtualserver

Creates and manages virtual node objects on your F5 device.

#### Providers

**Note:** Not all features are available with all providers. The providers below were based on F5 virtual server options you can read about [here](https://support.f5.com/kb/en-us/solutions/public/14000/100/sol14163.html).

* `forwarding_ip` - Forwards packets directly to the destination IP address specified in the client request, and has no pool members to load balance. (Available with `bandwidth_control`, `clone_pool`,`connection_limit`, `connection_mirroring`, `irules`, `last_hop_pool`, `protocol_client`, `source_port`, `source_translation`, and `traffic_class`.)
* `forwarding_layer_2` - Shares the same IP address as a node in an associated VLAN group. (Available with `bandwidth_control`, `clone_pool`,`connection_limit`, `connection_mirroring`, `default_pool`, `fallback_persistence`, `irules`, `last_hop_pool`, `persistence`, `protocol_client`, `source_port`, `source_translation`, and `traffic_class`.)
* `performance_http` - Increases the speed at which the virtual server processes HTTP requests, and has a FastHTTP profile associated with it. (Available with `bandwidth_control`, `clone_pool`, `default_pool`, `irules`, `last_hop_pool`, `persistence`, `protocol_client`, `source_port`, `source_translation`, and `traffic_class`.)
* `performance_l4` - Increases the speed at which the virtual server processes packets, and has a FastL4 profile associated with it. (Available with `bandwidth_control`, `clone_pool`,`connection_limit`, `connection_mirroring`, `default_pool`, `fallback_persistence`, `irules`, `last_hop_pool`, `persistence`, `protocol_client`, `source_port`, `source_translation`, and `traffic_class`.)
* `reject` - Rejects any traffic destined for the virtual server IP address. (Available with `irules`, `source_port`, and `traffic_class`.)
* `standard` - Directs client traffic to a load balancing pool, and is a general purpose virtual server. (Available with `address_translation`, `bandwidth_control`, `clone_pool`,`connection_limit`, `connection_mirroring`, `default_pool`, `fallback_persistence`, `irules`, `persistence`, `policies`, `port_translation`, `protocol_client`, `protocol_server`, `source_port`, `source_translation`, `standard_profiles` and `traffic_class`.)
* `stateless` - Improves the performance of UDP traffic over a standard virtual server in specific scenarios but with limited feature support. (Available with `address_translation`, `connection_limit`, `default_pool`, `last_hop_pool`, and `port_translation`.)

#### Features

**Note:** Not all features are available with all providers.

* `address_translation` - Supports address translation. (Available with `standard` and `stateless`.)
* `bandwidth_control` - Supports bandwidth control. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_http`, `performance_l4`, and `standard`.)
* `clone_pool` - Supports clone pools. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_http`, `performance_l4`, and `standard`.)
* `connection_limit` - Supports limiting connections. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_http`, `performance_l4`, `standard`, and `stateless`.)
* `connection_mirroring` - Supports mirroring connections. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_l4`, and `standard`.)
* `default_pool` - Supports setting a default pool. (Available with `forwarding_layer_2`, `performance_l4`, and `standard`.)
* `fallback_persistence` - Supports setting a fallback persistence profile. (Available with `forwarding_layer_2`, `performance_http`, `performance_l4`, `standard`, and `stateless`.)
* `irules` - Supports setting iRules. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_http`, `performance_l4`, `reject`, and `standard`.)
* `last_hop_pool` -  Supports a last hop pool. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_http`, `performance_l4`, and `stateless`.)
* `persistence` - Supports setting a persistence profile. (Available with `forwarding_layer_2`, `performance_http`, `performance_l4`, and `standard`.)
* `policies` - Supports policies. (Available with `standard`.)
* `port_translation` - Supports port translation. (Available with `standard` and `stateless`.)
* `protocol_client` - Supports client protocol profiles. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_http`, `performance_l4`, and `standard`.)
* `protocol_server` - Supports server protocol profiles. (Available with `standard`.)
* `source_port` - Supports source port setting. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_http`, `performance_l4`, `reject`, and `standard`.)
* `source_translation` - Supports source address translation. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_http`, `performance_l4`, and `standard`.)
* `standard_profiles` - Supports the standard set of profiles. (Available with `standard`.)
* `traffic_class` - Supports traffic class objects. (Available with `forwarding_ip`, `forwarding_layer_2`, `performance_http`, `performance_l4`, `reject`, and `standard`.)

#### Parameters

##### address_status

Determines whether the virtual server's IP should respond to pings based on pool member availability.

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

##### address_translation

Determines whether address translation is on or not. If the address is translated, the servers interpret the traffic as coming from the F5 and respond to the F5. However, if the address is not translated, the servers interpret the traffic as coming from the router and return the traffic there. Address translation  works only at layer 4 and below. (Requires `address_translation` feature.)

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

##### authentication_profiles

Enables you to use specific authentication profiles that make various traffic behaviors applicable to multiple protocols. The authentication profiles available when this parameter is enabled are: LDAP, RADIUS, TACACS+, SSL Client Certificate LDAP, SSL OCSP, and CRLDP. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### auto_last_hop

Allows the BIG-IP system to track the source MAC address of incoming connections and return traffic from pools to the source MAC address, regardless of the routing table.

Valid options: 'default', 'enabled', or 'disabled'

##### bandwidth_controller

Applies a bandwidth controller to enforce the total amount of bandwidth that can be used by the virtual server.

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### clone_pool_client

Copies traffic to IDS's prior to address translation.

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### clone_pool_server

Copies traffic to IDS's after address translation.

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### connection_limit

Sets the maximum number of concurrent connections allowed for the virtual server. Setting this to 0 turns off connection limits. (Requires `connection_limit` feature.)

Valid options: an integer.

##### connection_mirroring

Sets whether to mirror connection and persistence information to another device in order to prevent interruption in service during failover. (Requires `connection_mirroring` feature.)

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

##### connection_rate_limit

Sets the connection rate limit of the object.

Valid options: An integer or 'disabled'.

##### connection_rate_limit_destination_mask

Specifies the CIDR mask of connection destinations with rate limiting.

Valid options: An integer between 0 and 32.

##### connection_rate_limit_mode

Sets the connection rate limit mode.

Valid options:

* 'per_virtual_server'
* 'per_virtual_server_and_source_address'
* 'per_virtual_server_and_destination_address'
* 'per_virtual_server_destination_and_source_address'
* 'per_source_address'
* 'per_destination_address'
* 'per_source_and_destination_address'

##### connection_rate_limit_source_mask

Specifies the CIDR mask of connection sources with rate limiting.

Valid options: An integer between 0 and 32.

##### default_persistence_profile

Enables you to use specific persistence profiles that make various traffic behaviors applicable to multiple protocols. The persistence profiles available when this parameter is enabled are: Cookie, Destination Address Affinity, Hash, Microsoft Remote Desktop, SIP, Source Address Affinity, SSL, and Universal. (Requires `persistence` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'.

##### default_pool

Specifies a pool of nodes that F5 sends traffic to if not otherwise specified by another property such as an iRule or OneConnect profile. (Requires `default_pool` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'.

##### description

Sets the description of the virtual server.

Valid options: a string.

##### destination_address

Sets the IP address of the virtual server. Optionally includes a route domain ID. Eg: '10.0.5.5%3'

Valid options: IP Address

##### destination_mask

Specifies the netmask for a network virtual server, which clarifies whether the host is 0 or a wildcard representation. Is required for network virtual servers.

Valid options: Netmask

##### diameter_profile

Enables you to use a Diameter profile, which allows the BIG-IP system to send client-initiated Diameter messages to load balancing servers and ensure that those messages persist on the servers. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### dns_profile

Enables you to use a custom DNS profile to enable features such as: converting IPv6-formatted addresses to IPv4 format, DNS Express, and DNSSEC. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### ensure

Determines whether or not the resource should be present.

Valid options: 'present' or 'absent'

##### fallback_persistence_profile

Specifies the type of persistence that the BIG-IP system should use if it cannot use the default persistence. (Requires `fallback_persistence` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### fix_profile

Enables you to use Financial Information eXchange (FIX) protocol messages in routing, load balancing, persisting, and logging connections. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### ftp_profile

Defines the behavior of File Transfer Protocol (FTP) traffic. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### html_profile

Enables the virtual server to modify HTML content that passes through it, according to your specifications. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### http_compression_profile

Enables compression of HTTP content to reduce the amount of data to be transmitted and significantly reduce bandwidth usage. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### http_profile

Enables you to use an HTTP profile that ensures that HTTP traffic management suits your specific needs. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### irules

Enables the use of iRule objects on your virtual server. (Requires `irules` feature.)

Valid options: 'none' or '/< PARTITION >/< IRULE OBJECT NAME >'

##### last_hop_pool

Directs reply traffic to the last hop router using a last hop pool. **Note: This parameter overrides the auto_lasthop setting.**

Valid options: 'none' or '/< PARTITION >/< POOL NAME >'

##### name

Sets the name of the virtual server.

Valid options: a string.

##### nat64

Maps IPv6 subscriber private addresses to IPv4 Internet public addresses.

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

##### ntlm_conn_pool

Enables use of an encrypted challenge/response protocol to authenticate a user without sending the user's password over the network. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### oneconnect_profile

Enables connection pooling on your virtual server. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### policies

Enables use of custom /Partition/Object policies.(Requires `policies` feature.)

Valid options: Array

##### port_translation

Determines whether port translation is on or not. If the port is translated, the servers interpret the traffic as coming from the F5 and responds to the F5. However, if the port is not translated, the servers interpret the traffic as coming from the router and return the traffic there. (Requires `port_translation` feature.)

Valid options: 'enabled', 'disabled', true, false, 'yes', or 'no'

##### protocol

Sets the network protocol name for which you want the virtual server to direct traffic.

Valid options: 'all', 'tcp', 'udp', or 'sctp'

##### protocol_profile_client

Setting this parameter requires setting `protocol_profile_server` as well. If you want to default this value, set `protocol_profile_server` to the same value as `protocol_profile_client`.

Enables you to use specific protocol profiles that expand the capacities of specific protocols pertaining to incoming connections from a web client. The protocol profiles available when this parameter is enabled are: Fast L4, Fast HTTP, HTTP Class, TCP, UDP, and SCTP. (Requires `protocol_client` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### protocol_profile_server

Setting this parameter requires setting `protocol_profile_client` as well. If you want to default this value, set `protocol_profile_client` to the same value as `protocol_profile_server`.

Enables you to use specific protocol profiles that expand the capacities of specific protocols pertaining to F5's connection to the virtual server's it's sending traffic to. The protocol profiles available when this parameter is enabled are: Fast L4, Fast HTTP, HTTP Class, TCP, UDP, and SCTP. (Requires `protocol_server` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### provider

Specifies the backend to use for the f5_virtualserver resource. You seldom need to specify this, as Puppet usually discovers the appropriate provider for your platform.

Available providers can be found in the "Providers" section above.

##### rate_class

Enables you to define the throughput limitations and packet scheduling method that you want the BIG-IP system to apply to all traffic that the rate class handles.

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### request_adapt_profile

Instructs an HTTP virtual server to send a request to a named virtual server of type Internal for possible modification by an Internet Content Adaptation Protocol (ICAP) server. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### request_logging_profile

Enables you to configure data within a log file for requests and responses in accordance with specified parameters. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### response_adapt_profile

Instructs an HTTP virtual server to send a response to a named virtual server of type Internal for possible modification by an Internet Content Adaptation Protocol (ICAP) server. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### rewrite_profile

Specifies the TCL expression that the system uses to rewrite the request URI that is forwarded to the server without sending an HTTP redirect to the client. **Note:** If you use static text rather than a TCL expression, the system maps the specified URI for every incoming request. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### rtsp_profile

Enables a client system to control a remote streaming-media server and allow time-based access to files on a server. (Requires 'standard_profiles' feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### service_port

Specifies a service name or port number for which you want to direct traffic. **This parameter is required.** (Requires 'service_port' feature.)

Valid options: '*' or integers

##### sip_profile

Configures how the virtual server handles SIP sessions. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### socks_profile

Configures the BIG-IP system to handle proxy requests and function as a gateway. Configuring browser traffic to use the proxy allows you to control whether to allow or deny a requested connection. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### source

Specifies the CIDR notation for traffic source address. Optionally includes a route domain ID.

Valid options: '< IPADDRESS[%ID]/ 0 - 32 >'. For instance: '78.0.0.0%3/8'.

##### source_address_translation

Assigns an existing SNAT or LSN pool to the virtual server, or enables the Automap feature. When you use this setting, the BIG-IP system automatically maps all original source IP addresses passing through the virtual server to an address in the SNAT or LSN pool. (Requires `source_translation` feature.)

Valid options: 'none', 'automap', { 'snat' => '/Partition/pool_name'}, or { 'lsn' => '/Partition/pool_name'}

##### source_port

Specifies whether the system preserves the source port of the connection. (Requires `source_port` feature.)

Valid options: 'preserve', 'preserve_strict', or 'change'

##### spdy_profile

Minimizes latency of HTTP requests by multiplexing streams and compressing headers. When you assign a SPDY profile to an HTTP virtual server, the HTTP virtual server informs clients that a SPDY virtual server is available to respond to SPDY requests. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### ssl_profile_client

Enables the the BIG-IP system to handle authentication and encryption tasks for any SSL connection coming into a BIG-IP system from a client system. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### ssl_profile_server

Enables the BIG-IP system to handle encryption tasks for any SSL connection being sent from a BIG-IP system to a target server. A server SSL profile is able to act as a client by presenting certificate credentials to a server when authentication of the BIG-IP system is required. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### state

Sets the state of the virtual server.

Valid options: 'enabled', 'disabled', or 'forced_offline'

##### statistics_profile

Provides user-defined statistical counters.

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### stream_profile

Searches for and replaces strings within a data stream. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### traffic_class

Allows you to classify traffic according to a set of criteria that you define, such as source and destination IP addresses, for the virtual server.

Valid options: An array of /Partition/traffic_class_name objects

##### vlan_and_tunnel_traffic

Specifies the names of VLANs for which the virtual server is enabled or disabled.

Valid options: '< 'all','enabled', or 'disabled' > => [ '/Partition/object' ]}'

##### vs_score

Weight taken into account by the Global Traffic Manager.

Valid options: an integer between 0 and 100  (Note: value is a percentage.)

##### web_acceleration_profile

Allows the BIG-IP system to store HTTP objects in memory and reuse these objects for subsequent connections. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'

##### xml_profile

Defines the formatting and attack pattern checks for the security policy. (Requires `standard_profiles` feature.)

Valid options: 'none' or '/< PARTITION >/< VIRTUAL SERVER NAME >'.

### f5_partition

Manages partitions on the F5 device. See [f5 documentation](https://support.f5.com/kb/en-us/solutions/public/7000/200/sol7230.html) for information about configuring F5 partitions.

#### Parameters

##### name

Specifies the name of the partition resource to manage.

Valid options: a string.

##### description

Sets the description of the node.

Valid options: a string.

### f5_vlan

Manages virtual LANs on the F5 device. See [f5 documentation](https://techdocs.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/bigip-system-ecmp-mirrored-clustering-12-1-0/2.html) for information about configuring F5 VLANS.

#### Parameters

##### name

Specifies the name of the partition resource to manage.

Valid options: a string.

##### description

Sets the description of the node.

Valid options: a string.

#### vlan_tag

Specifies the VLAN ID. If you do not specify a VLAN ID, the BIG-IP system assigns an ID automatically.

Valid range: 1 - 4094.

##### source_check

Causes the BIG-IP system to verify that the return path of an initial packet is through the same VLAN from which the packet originated.

Valid options: 'enabled' or 'disabled'.

##### mtu

Specifies the Maximum Transmission Unit.

Valid range: 576 - 65535.

##### fail_safe

Triggers fail-over in a redundant system when certain VLAN-related events occur.

Valid options: 'enabled' or 'disabled'.

##### fail_safe_timeout

Specifies the number of seconds that a system can run without detecting network traffic on this VLAN before it takes the fail-safe action.

Valid range: 0 - 4294967295.

##### fail_safe_action

Specifies the action that the system takes when it does not detect any traffic on this VLAN, and the timeout has expired. The default is 'reboot'. Valid options:

* 'reboot': The system reboots.
* 'restart-all': The system restarts all services.

##### auto_last_hop

Allows the BIG-IP system to track the source MAC address of incoming connections and return traffic from pools to the source MAC address, regardless of the routing table.

Valid options: 'default', 'enabled', or 'disabled'.

##### cmp_hash

Specifies how the traffic on the VLAN will be disaggregated. The value selected determines the traffic disaggregation method. You can choose to disaggregate traffic based on `src-ip`, `dst-ip`, or default, which specifies that the default CMP hash uses L4 ports.

Valid options: 'default', 'src-ip' or 'dst-ip'.

##### dag_round_robin

Specifies whether some of the stateless traffic on the VLAN should be disaggregated in a round-robin order instead of using a static hash.

Valid options: 'enabled' or 'disabled'

##### sflow_polling_interval

Specifies the maximum interval in seconds between two pollings.

Valid range: 0 - 86400.

##### sflow_sampling_rate

Specifies the ratio of packets observed to the samples generated.

Valid range: 0 - 102400.

##### interface

An array of interfaces that this vlan resource is bound to.

Correct format example is:

`[{name => '1.1', tagged => true}, {name => '2.1', tagged => true}]`

### f5_selfip

Sets the self IP address on the BIG-IP system that you associate with a VLAN, to access hosts in that VLAN. By virtue of its netmask, a self IP address represents an address space; that is, a range of IP addresses spanning the hosts in the VLAN, rather than a single host address. You can associate self IP addresses not only with VLANs, but also with VLAN groups

#### Parameters

##### name

Specifies the name of the selfip to manage.

Valid options: a string.

##### address

Specify either an IPv4 or an IPv6 address. For an IPv4 address, you must specify a /32 IP address per RFC 3021 and a CIDR range. EG 9.9.9.9/255

Valid options: ip/cidr

##### vlan

Specifies the VLAN associated with this self IP address.

Valid options: string

##### traffic_group

Specifies the traffic group to associate with the self IP. You can click the box to have the self IP inherit the traffic group from the root folder, or clear the box to select a specific traffic group for the self IP.

Valid options: string

##### inherit_traffic_group

Whether to inherit the traffic group from the current partition or path.

Valid options: true, false.

##### port_lockdown

Specifies the protocols and services from which this self IP can accept traffic. Note that fewer active protocols enhances the security level of the self IP and its associated VLANs. Accepts an array of: 'default', 'all', protocol:port (for example, `["TCP:80", "UDP:55"]`). Options behave as follows:

* `protocol:port`: the protocols and ports to activate on this self IP.
* `default`: Activates only the default protocols and services. You can determine the supported protocols and services by running the tmsh list net self-allow defaults command on the command line. May be combined with further protocol:port values.
* `all`: Activates all TCP and UDP services on this self IP. May not be combined with any other value.
* `none`: Specifies that this self IP accepts no traffic. May not be combined with any other values.

### f5_dns

Manages system DNS settings on the F5 device. See [F5 documentation](https://support.f5.com/csp/article/K26057357) to learn more about F5 DNS. f5_dns has no `ensure => absent` functionality.


#### Parameters

###### name

Specifies the name of the DNS resource to manage.

Valid options: a string.

##### description

Sets the description of the DNS.

Valid options: a string.

##### name_servers

Specifies the name servers that the system uses to validate DNS lookups, and resolve host names.

Correct format example is: ["4.2.2.2", "8.8.8.8”]

##### search
Specifies the domains that the system searches for local domain lookups, to resolve local host names.

Correct format example is: ["localhost","f5.local”]

#### Example
~~~puppet
  f5_dns { '/Common/dns':
    name_servers         => ["4.2.2.2", "8.8.8.8"],
    search               => ["localhost","f5.local"],
   }
~~~


### f5_ntp

Manages system NTP settings on the F5 device. See [F5 documentation](https://support.f5.com/csp/article/K13380) to learn more about F5 DNS.

#### Parameters

###### name
Specifies the name of the NTP resource to manage.

Valid options: a string.

##### description

Sets the description of the NTP.

Valid options: a string.

##### servers

Specifies the time servers that the system uses to update the system time

Correct format example is: ['0.pool.ntp.org', '1.pool.ntp.org']

##### timezone

Specifies the timezone

#### Example

~~~puppet
  f5_ntp { '/Common/ntp':
    servers  => ['0.pool.ntp.org', '1.pool.ntp.org'],
    timezone => 'UTC',
   }
~~~

### f5_globalsetting

Manages system global settings on the F5 device. See [F5 documentation](https://support.f5.com/csp/article/K14938) to learn more about F5 global setting. f5_globalsetting has no `ensure => absent` functionality.

#### Parameters

###### name
Specifies the name of the global setting resource to manage.

Valid options: a string.

##### description

Sets the description of the global setting.

Valid options: a string.

##### hostname

Specifies a local name for the system.

The default value is bigip1.

##### gui_setup

Enables or disables the Setup utility in the browser-based Configuration utility.

The default value is enabled.

#### Example

~~~puppet
  f5_globalsetting { '/Common/globalsetting':
    hostname  => "bigip-a.f5.local",
    gui_setup => "disabled",
   }
~~~

### f5_user

Manages the user account on the F5 device. See [F5 documentation](https://techdocs.f5.com/kb/en-us/products/big-ip_ltm/manuals/product/bigip-user-account-administration-13-0-0.html) to learn more about F5 user account.

#### Parameters

###### name

Specifies the name of the user account to manage.

$name is mandatory for all users in the format of `my_user`. Without $name specification, the  $name defaults to the value of $title, which is in the format of `/Partition/title`, such as `/Common/my_user`.

Valid options: a string.

##### description

Sets the description of the user account.

Valid options: a string.

##### ensure

Determines whether the user resource is present or absent.

Valid options: 'present' or 'absent'.

##### password

Set the user password during creation or modification without prompting or confirmation.

#### Example

##### Add a user
~~~puppet
  f5_user { '/Common/joe':
    name     => 'joe',
    ensure   => 'present',
    password => 'joe',
  }
~~~

##### Delete a user
~~~puppet
  f5_user { '/Common/joe':
    name   => 'joe',
    ensure => 'absent',
  }
~~~

### f5_route

Configure route on the Big-IP system. See [F5 documentation](https://support.f5.com/csp/article/K13833) to learn more about F5 Configuring Routes.

#### Parameters

###### name

Specifies the identifier that, when appended to BIG-IP system addresses, indicates the specific route domain in the partition to which the address applies.

Valid options: a string.

##### description

Specifies descriptive text that identifies the route.

Valid options: a string.

##### gw

Specifies a gateway address for the route.

Valid options: IPv4 or IPv6 addresses.

##### mtu

Sets a specific maximum transmission unit (MTU).

Valid options: 0 - 65535.

##### network

The destination subnet and netmask for the route.

Valid options: IP address followed by netmask.

##### pool

Specifies a gateway pool, which allows multiple, load-balanced gateways to be used for the route.

Valid options: a string.

##### tm_interface

Specifies a VLAN for the route. This can be a VLAN or VLAN group.

Valid options: a string.

#### Example

##### Create default route
~~~puppet
  f5_route { '/Common/Default':
    ensure  => 'present',
    gw      => "10.1.20.253",
    mtu     => '0',
    network => "0.0.0.0/0",
  }
~~~

##### Delete default route
~~~puppet
  f5_route { '/Common/Default':
    ensure => 'absent',
~~~


### f5_root

Changes the password of the root user on the Big-IP system. The root user can be used for SSH to obtain remote access to the device. A root user can not send REST requests it is not a REST Framework user. f5_root has no `ensure => absent` functionality.

#### Parameters

###### name

Specifies the name of the root user to manage.

Valid options: a string.

##### description

Sets the description of the root user.

Valid options: a string.

##### old_password

The root user’s old password.

Valid options: a string.

##### new_password

The root user’s new password.

Valid options: a string.

#### Example

~~~puppet
  f5_root { '/Common/root':
    old_password => 'default',
    new_password => 'default',
  }
~~~

### f5_license

Manage license installation and activation on BIG-IP devices. f5_license has no `ensure => absent` functionality

#### Parameters

###### name

Specifies the name.

Valid options: a string.

##### description

Sets the description.

Valid options: a string.

##### registration_key

The registration key to use to license the BIG-IP.

#### Example

~~~puppet
  f5_license { '/Common/license':
    registration_key => "GKWPN-NDMLV-CXSTE-NWDEX-PCFPTLV"
  }
~~~

### f5_selfdevice

Change device name from default bigip1 under 'Device Management > Devices'. This is achieved by using tmsh `mv`command, and hence has no `ensure => absent` functionality.

NOTE: This does not impact the hostname

#### Parameters

###### name

Specifies the name of device name to manage.

Valid options: a string.

##### description

Sets the description of device name.

Valid options: a string

##### target

Specifies the target device name.

Valid options: a string

#### Examples

rename the self device:
~~~puppet
  f5_selfdevice { '/Common/bigip-a.f5.local':
    target =>"bigip-a.f5.local",
  }
~~~

reset the device name:
~~~puppet
  f5_selfdevice { '/Common/bigip1':
    target =>"bigip1",
  }
~~~

### f5_device

Manages device IP configuration settings for HA on a BIG-IP. Each BIG-IP device has synchronization and failover connectivity information (IP addresses) that you define as part of HA pairing or clustering. This module allows you to configure that information.

#### Parameters

###### name

Specifies the name of the device to manage

Valid options: a string.

##### description

Sets the description of the device IP configuration settings

Valid options: a string.

##### configsync_ip

Local IP address that the system uses for ConfigSync operations.

##### mirror_ip

Specifies the primary IP address for the system to use to mirror connections.

#### Example

~~~puppet
  f5_device{ '/Common/bigip-a.f5.local':
    ensure        => 'present',
    configsync_ip => '10.1.30.1',
    mirror_ip     => '10.1.30.1',
  }
~~~

### f5_addtotrust

Manage the trust relationships between BIG-IPs. In this task we will add BIG-IP-B as a trusted peer of BIG-IP-A. This is achieved by using tmsh command, and hence has no `ensure => absent` functionality.

#### Parameters

###### name

Specifies the name

Valid options: a string.

##### description

Sets the description.

Valid options: a string.

##### device

Specify the FQDN or management-ip of the new device.

##### device_name

Specify the name of the peer device to add.

##### username

Specify the username when adding the new device.

##### password

Specify the password when adding the new device.

#### Example

~~~puppet
  f5_addtotrust { '/Common/addtotrust':
    device     => "10.192.74.112",
    device_name => "bigip-b.f5.local",
    username   => "admin",
    password   => "admin",
  }
~~~

### f5_devicegroup

Manage device groups on a BIG-IP. Managing device groups allows you to create HA pairs and clusters of BIG-IP devices.

#### Parameters

###### name

Specifies the name of device group to manage.

Valid options: a string.

##### description

Sets the description of the device group.

Valid options: a string.

##### ensure

Determines whether the device group resource is present or absent.

Valid options: 'present' or 'absent'.

##### type

Specifies if the device-group will be used for failover or resource syncing

Valid options: a string.

##### auto_sync

Specifies if the device-group will automatically sync configuration data to its members

Valid options: a string.

##### devices

An array of devices to be added to the device group.

#### Example

##### Create a device group
~~~puppet
  f5_devicegroup{ '/Common/DeviceGroup1':
    ensure    => 'present',
    type      => 'sync-failover',
    auto_sync => 'enabled',
    devices   => [ "bigip-a.f5.local","bigip-b.f5.local" ],
  }
~~~

##### Delete a device group
~~~puppet
  f5_devicegroup{ '/Common/DeviceGroup1':
    ensure => 'absent',
  }
~~~


### f5_configsync

Perform initial sync of the Device Group. This is achieved by using tmsh `run` command, and hence has no `ensure => absent` functionality.

#### Parameters

###### name

Specifies the name.

Valid options: a string.

##### description

Sets the description.

Valid options: a string.

##### to_group

Specifies the 'to-group' device group to run a config-sync

#### Example

~~~puppet
  f5_configsync { '/Common/config-sync':
    to_group => "DeviceGroup1",
  }
~~~


### f5_command

Sends an arbitrary command to an BIG-IP node. TMSH command has no `ensure => absent` functionality.It provides a way to execute native tmsh or bash commands ( using the REST API (/mgmt/tm/util/bash)

#### Parameters

###### name

Specifies the name.

Valid options: a string.

##### description

Sets the description.

Valid options: a string.

##### tmsh

Specifies the command to send to the remote BIG-IP device over the configured provider

#### Example

~~~puppet
  f5_command { '/Common/tmsh':
    tmsh  => "tmsh create ltm node 2.2.2.2",
  }
~~~

### f5_persistencecookie

Manage Virtual server Cookie persistence profile

#### Parameters

###### name

Specifies the name of Cookie persistence profile to manage.

Valid options: a string.

##### description

Sets the description of the Cookie persistence profile.

Valid options: a string.

##### ensure

Determines whether the Cookie persistence profile resource is present or absent.

Valid options: 'present' or 'absent'.

##### method

Specifies the type of cookie processing that the system uses. The default value is insert.

Valid options: 'insert', 'passive', 'rewrite'

##### cookie_name

Specifies a unique name for the profile.

Valid options: a string.

##### httponly

Specifies whether the httponly attribute should be enabled or disabled for the inserted cookies. The default value is enabled.

Valid options: 'enabled', 'disabled'

##### secure

Specifies whether the secure attribute should be enabled or disabled for the inserted cookies

Valid options: 'enabled', 'disabled'

##### always_send

Specifies, when enabled, that the cookie persistence entry will be sent to the client on every response, rather than only on the first response.

Valid options: 'enabled', 'disabled'

##### expiration

Specifies the cookie expiration date in the format d:h:m:s, h:m:s, m:s or seconds. Hours 0-23, minutes 0-59, seconds 0-59. The time period must be less than 24856 days. You can use "session-cookie" (0 seconds) to indicate that the cookie expires when the browser closes.

##### cookie_encryption

Specifies the way in which cookie format will be used: "disabled": generate old format,unencrypted, "preferred": generate encrypted cookie but accept both encrypted and old format, and "required": cookie format must be encrypted. Default is required.

Valid options: 'enabled', 'disabled'

#### Example

##### Create a Cookie persistence profile
~~~puppet
  f5_persistencecookie { '/Common/cookie1':
    ensure            => 'present',
    method            => 'insert',
    cookie_name       => 'name1',
    httponly          => 'enabled',
    secure            => 'enabled',
    always_send       => 'disabled',
    expiration        => '0',
    cookie_encryption => 'disabled',
}
~~~

##### Delete a Cookie persistence profile
~~~puppet
  f5_persistencecookie { '/Common/cookie1':
    ensure => 'absent',
  }
~~~

### f5_persistencedestaddr

Manage Virtual server Destination Address Affinity persistence profile on a BIG-IP

#### Parameters

###### name

Specifies the name of Destination Address Affinity persistence profile to manage

Valid options: a string.

##### description

Sets the description of the Destination Address Affinity persistence profile

Valid options: a string.

##### ensure

Determines whether the persistence profile resource is present or absent.

Valid options: 'present' or 'absent'.

##### match_across_pools

Specifies, when enabled, that the system can use any pool that contains this persistence record. The default value is disabled.

Valid options: 'enabled', 'disabled'

##### match_across_services

Specifies, when enabled, that all persistent connections from a client IP address, which go to the same virtual IP address, also go to the same node. The default value is disabled.

Valid options: 'enabled', 'disabled'

##### match_across_virtuals

Specifies, when enabled, that all persistent connections from the same client IP address go to the same node. The default value is disabled.

Valid options: 'enabled', 'disabled'

##### hash_algorithm

Specifies whether the system uses the hash algorithm defined by the Cache Array Routing Protocol (CARP) to select a pool member.

Valid options: default, 'carp'.

##### mask

Specifies an IP mask. This is the mask used by simple persistence for connections.

Valid options: Netmask

##### timeout

Specifies the duration of the persistence entries. The default value is 180 seconds.

Valid options: an integer.

##### override_connection_limit

Specifies, when enabled, that the pool member connection limits are not enforced for persisted clients. Per-virtual connection limits remain hard limits and are not disabled. The default value is disabled.

Valid options: 'enabled', 'disabled'


#### Example

##### Create Destination Address Affinity persistence profile
~~~puppet
  f5_persistencedestaddr { '/Common/dest_addr1':
     ensure                    => 'present',
     match_across_pools        => 'enabled',
     match_across_services     => 'enabled',
     match_across_virtuals     => 'enabled',
     hash_algorithm            => 'carp',
     mask                      => '255.255.0.0',
     timeout                   => '180',
     override_connection_limit => 'enabled',
  }
~~~

##### Delete a Destination Address Affinity persistence profile
~~~puppet
  f5_persistencedestaddr { '/Common/dest_addr1':
    ensure => 'absent',
  }
~~~

### f5_persistencehash

Manage device groups on a BIG-IP. Managing device groups allows you to create HA pairs and clusters of BIG-IP devices.

#### Parameters

###### name

Specifies the name of device group to manage.

Valid options: a string.

##### description

Sets the description of the device group.

Valid options: a string.

##### ensure

Determines whether the device group resource is present or absent.

Valid options: 'present' or 'absent'.

##### type

Specifies if the device-group will be used for failover or resource syncing

Valid options: a string.

##### auto_sync

Specifies if the device-group will automatically sync configuration data to its members

Valid options: a string.

##### devices

An array of devices to be added to the device group.

#### Example

##### Create a device group
~puppet
  f5_devicegroup{ '/Common/DeviceGroup1':
    ensure    => 'present',
    type      => 'sync-failover',
    auto_sync => 'enabled',
    devices   => [ "bigip-a.f5.local","bigip-b.f5.local" ],
  }
~

##### Delete a device group
~puppet
  f5_devicegroup{ '/Common/DeviceGroup1':
    ensure => 'absent',
  }
~

### f5_persistencesourceaddr

Manage device groups on a BIG-IP. Managing device groups allows you to create HA pairs and clusters of BIG-IP devices.

#### Parameters

###### name

Specifies the name of device group to manage.

Valid options: a string.

##### description

Sets the description of the device group.

Valid options: a string.

##### ensure

Determines whether the device group resource is present or absent.

Valid options: 'present' or 'absent'.

##### type

Specifies if the device-group will be used for failover or resource syncing

Valid options: a string.

##### auto_sync

Specifies if the device-group will automatically sync configuration data to its members

Valid options: a string.

##### devices

An array of devices to be added to the device group.

#### Example

##### Create a device group
~puppet
  f5_devicegroup{ '/Common/DeviceGroup1':
    ensure    => 'present',
    type      => 'sync-failover',
    auto_sync => 'enabled',
    devices   => [ "bigip-a.f5.local","bigip-b.f5.local" ],
  }
~

##### Delete a device group
~puppet
  f5_devicegroup{ '/Common/DeviceGroup1':
    ensure => 'absent',
  }
~

### f5_persistencessl

Manage device groups on a BIG-IP. Managing device groups allows you to create HA pairs and clusters of BIG-IP devices.

#### Parameters

###### name

Specifies the name of device group to manage.

Valid options: a string.

##### description

Sets the description of the device group.

Valid options: a string.

##### ensure

Determines whether the device group resource is present or absent.

Valid options: 'present' or 'absent'.

##### type

Specifies if the device-group will be used for failover or resource syncing

Valid options: a string.

##### auto_sync

Specifies if the device-group will automatically sync configuration data to its members

Valid options: a string.

##### devices

An array of devices to be added to the device group.

#### Example

##### Create a device group
~puppet
  f5_devicegroup{ '/Common/DeviceGroup1':
    ensure    => 'present',
    type      => 'sync-failover',
    auto_sync => 'enabled',
    devices   => [ "bigip-a.f5.local","bigip-b.f5.local" ],
  }
~

##### Delete a device group
~puppet
  f5_devicegroup{ '/Common/DeviceGroup1':
    ensure => 'absent',
  }
~

### f5_persistenceuniversal

Manage device groups on a BIG-IP. Managing device groups allows you to create HA pairs and clusters of BIG-IP devices.

#### Parameters

###### name

Specifies the name of device group to manage.

Valid options: a string.

##### description

Sets the description of the device group.

Valid options: a string.

##### ensure

Determines whether the device group resource is present or absent.

Valid options: 'present' or 'absent'.

##### type

Specifies if the device-group will be used for failover or resource syncing

Valid options: a string.

##### auto_sync

Specifies if the device-group will automatically sync configuration data to its members

Valid options: a string.

##### devices

An array of devices to be added to the device group.

#### Example

##### Create a device group
~puppet
  f5_devicegroup{ '/Common/DeviceGroup1':
    ensure    => 'present',
    type      => 'sync-failover',
    auto_sync => 'enabled',
    devices   => [ "bigip-a.f5.local","bigip-b.f5.local" ],
  }
~

##### Delete a device group
~puppet
  f5_devicegroup{ '/Common/DeviceGroup1':
    ensure => 'absent',
  }
~

### f5_profilehttp

Manage Virtual server HTTP traffic profile

#### Parameters

###### name

Specifies the name of HTTP traffic profile to manage.

Valid options: a string.

##### description

Sets the description of the HTTP traffic profile

Valid options: a string.

##### ensure

Determines whether the HTTP traffic profile resource is present or absent.

Valid options: 'present' or 'absent'.

##### fallback_host

Specifies an HTTP fallback host. HTTP redirection allows you to redirect HTTP traffic to another protocol identifier, host name, port number, or URI path. For example, if all members of the targeted pool are unavailable (that is, the members are disabled, marked as down, or have exceeded their connection limit), the system can redirect the HTTP request to the fallback host, with the HTTP reply Status Code 302 Found.

Valid options: a string.

##### fallback_status_codes

Specifies one or more three-digit status codes that can be returned by an HTTP server.

Valid options: a string.

#### Example

##### Create a HTTP traffic profile
~~~puppet
    f5_profilehttp { '/Common/http-profile_1':
       ensure                          => 'present',
       fallback_host                   => "redirector.siterequest.com",
       fallback_status_codes           => ['500'],
    }
~~~

##### Delete a HTTP traffic profile
~~~puppet
    f5_profilehttp { '/Common/http-profile_1':
      ensure => 'absent',
    }
~~~

### f5_profileclientssl

Manage Virtual server client-side proxy SSL profile

#### Parameters

###### name

Specifies the name of client-side proxy SSL profile to manage.

Valid options: a string.

##### description

Sets the description of the client-side proxy SSL profile

Valid options: a string.

##### ensure

Determines whether the client-side proxy SSL profile resource is present or absent.

Valid options: 'present' or 'absent'.

##### cert

Specifies the name of the certificate installed on the traffic management system for the purpose of terminating or initiating an SSL connection.

Valid options: a string.

##### key

Specifies the name of a key file that you generated and installed on the system. The default key name is default.key.

Valid options: a string.

##### proxy_ssl

Enables proxy SSL mode, which requires a corresponding server SSL profile with proxy-ssl enabled to allow for modification of application data within an SSL tunnel.o

Valid options: 'enabled', 'disabled'

##### proxy_ssl_passthrough

Enables proxy SSL passthrough mode, which requires a corresponding server SSL profile with proxy-ssl-passthrough enabled to allow for modification of application data within an SSL tunnel.

Valid options: 'enabled', 'disabled'

#### Example

##### Create a client-side proxy SSL profile
~~~puppet
    f5_profileclientssl {'/Common/clientssl-profile1':
       ensure                          => 'present',
       cert                            =>"/Common/default.crt",
       key                             =>"/Common/default.key",
       proxy_ssl                       => 'enabled',
       proxy_ssl_passthrough           => 'enabled',
    }
~~~

##### Delete a device group
~~~puppet
    f5_profileclientssl {'/Common/clientssl-profile1':
      ensure => 'absent',
    }
~~~

### f5_profileserverssl

Manage Virtual server server-side proxy SSL profile

#### Parameters

###### name

Specifies the name of Virtual server server-side proxy SSL profile to manage.

Valid options: a string.

##### description

Sets the description of the Virtual server server-side proxy SSL profile

Valid options: a string.

##### ensure

Determines whether the Virtual server server-side proxy SSL profile resource is present or absent.

Valid options: 'present' or 'absent'.

##### cert

Specifies the name of the certificate installed on the traffic management system for the purpose of terminating or initiating an SSL connection. The default value is none.

Valid options: a string.

##### key

Specifies the name of the key installed on the traffic management system for the purpose of terminating or initiating an SSL connection. The default value is none.

Valid options: a string.

##### proxy_ssl

Enables proxy SSL mode, which requires a corresponding client SSL profile with proxy-ssl enabled to allow for modification of application data within an SSL tunnel.

Valid options: 'enabled', 'disabled'

##### proxy_ssl_passthrough

Enables proxy SSL passthrough mode, which requires a corresponding client SSL profile with proxy-ssl-passthrough enabled to allow for modification of application data within an SSL tunnel.

Valid options: 'enabled', 'disabled'

#### Example

##### Create a server-side proxy SSL profile
~~~puppet
    f5_profileserverssl {'/Common/serverssl-profile1':
       ensure                          => 'present',
       cert                            =>"/Common/default.crt",
       key                             =>"/Common/default.key",
       proxy_ssl                       => 'enabled',
       proxy_ssl_passthrough           => 'enabled',
    }
~~~

##### Delete a server-side proxy SSL profile
~~~puppet
    f5_profileserverssl {'/Common/serverssl-profile1':
      ensure => 'absent',
    }
~~~

### f5_sslkey

Import SSL keys from BIG-IP. This is achieved by using tmsh mvcommand, and hence has no ensure => absent functionality.

#### Parameters

###### name

Specifies the name of SSL key to manage.

Valid options: a string.

##### description

Sets the description of the SSL key.

Valid options: a string.

##### keyname

Specifies name of the key

Valid options: a string.

##### from_local_file

Specifies the exiting key file with full path that the system extracts the key text from.

Valid options: a string.

#### Example

##### Create an SSL key
~~~puppet
f5_sslkey { '/Common/sslkey':
    keyname  => "test",
    from_local_file => "/var/tmp/test.key",
}
~~~


### f5_sslcertificate

Import SSL certificate from BIG-IP. This is achieved by using tmsh mvcommand, and hence has no ensure => absent functionality.

#### Parameters

###### name

Specifies the name of SSL certificate to manage.

Valid options: a string.

##### description

Sets the description of the SSL certificate.

Valid options: a string.

##### certificate_name

Specifies the name of the certificate

Valid options: a string.

##### rom_local_file

Specifies the exiting certificate file with full path that the system extracts the certificate text from.

Valid options: a string.


#### Example

##### Create an SSL certificate
~~~puppet
f5_sslcertificate { '/Common/sslcertificate':
    certificate_name  => "test",
    from_local_file => "/var/tmp/test.crt",
}
~~~

### f5_snat

Manage Secure network address translation (SNAT)

#### Parameters

###### name

Specifies the name of SNAT

Valid options: a string.

##### description

Sets the description of the SNAT.

Valid options: a string.

##### ensure

Determines whether the SNAT resource is present or absent.

Valid options: 'present' or 'absent'.

##### snatpool

Specifies the name of a SNAT pool. You can only use this option when automap and translation are not used.

Valid options: a string.

##### origins

Specifies, for each SNAT that you create, the origin addresses that are to be members of that SNAT.

Valid options: an array

#### Example

##### Create SNAT
~~~puppet
    f5_snat { '/Common/snat_list1':
       ensure   => 'present',
       snatpool => ['/Common/snat_pool1'],
       origins  => [{"name"=>"10.0.0.0/8"}],
    }
~~~

##### Delete SNAT
~~~puppet
    f5_snatpool { '/Common/snat_pool1':
      ensure => 'absent',
    }
~~~

### f5_snatpool

Manage SNAT pools on a BIG-IP

#### Parameters

###### name

Specifies the name of the SNAT pool member.

Valid options: a string.

##### description

Sets the description of the SNAT pool.

Valid options: a string.

##### ensure

Determines whether the SNAT pool resource is present or absent.

Valid options: 'present' or 'absent'.

##### members

An array of SNAT pool members that belong to this SNAT pool.

#### Example

##### Create a device group
~~~puppet
  f5_snatpool { '/Common/snat_pool1':
    ensure  => 'present',
    members => ["/Common/1.1.1.1", "/Common/1.1.1.2", "/Common/1.1.1.3"],
  }
~~~

##### Delete a device group
~~~puppet
  f5_snatpool { '/Common/snat_pool1':
    ensure => 'absent',
  }
~~~

### f5_datagroup

Manage Internal data group

#### Parameters

###### name

Specifies the name of Internal data group to manage.

Valid options: a string.

##### description

Sets the description of the Internal data group

Valid options: a string.

##### ensure

Determines whether the Internal data group resource is present or absent.

Valid options: 'present' or 'absent'.

##### type

Specifies the type of data group.

Valid options: 'ip','string', 'integer'

##### records

Specifies an IP address, or string  of the string record, or  integer value for the integer record to add to the data group.

#### Example

##### Create Internal data group
~~~puppet
    f5_datagroup { '/Common/datagroup1':
       ensure                          => 'present',
       type                            => 'ip',
       records                         => [{'data' => '', 'name' => '64.12.96.0/19'}, {'data' => '', 'name' => '195.93.16.0/20'}],
    }

    f5_datagroup { '/Common/datagroup2':
       ensure                          => 'present',
       type                            => 'string',
       records                         => [{'data' => '', 'name' => '.gif'}, {'data' => '', 'name' => '.jpg'}],
    }

    f5_datagroup { '/Common/datagroup3':
       ensure                          => 'present',
       type                            => 'integer',
       records                         => [{'data' => '', 'name' => '1'}, {'data' => '', 'name' => '2'}],
    }
~~~

##### Delete Internal data group
~~~puppet
    f5_datagroup { '/Common/datagroup1':
      ensure => 'absent',
    }
    f5_datagroup { '/Common/datagroup2':
      ensure => 'absent',
    }
    f5_datagroup { '/Common/datagroup3':
      ensure => 'absent',
    }
~~~

### f5_datagroupexternal

Manage External data group

#### Parameters

###### name

Specifies the name of External data group  to manage.

Valid options: a string.

##### description

Sets the description of the External data group

Valid options: a string.

##### ensure

Determines whether the device group resource is present or absent.

Valid options: 'present' or 'absent'.

##### external_file_name

Specifies an external data group file.

Valid options: a string.

#### Example

##### Create an external data group
~~~puppet
    f5_datagroupexternal { '/Common/datagroupext1':
      ensure             => 'present',
      external_file_name => '/Common/add_dg1',
    }
~~~

##### Delete an external data group
~~~puppet
    f5_datagroupexternal { '/Common/datagroupext1':
      ensure => 'absent',
    }
~~~

## Limitations

F5 version v12.1 or greater.
Puppet Enterprise: 2016.4.x or greater.

## Development

Puppet modules on the Puppet Forge are open projects, and community contributions are essential for keeping them great. Please follow our guidelines when contributing changes.
For more information, see our [module contribution guide.](https://docs.puppetlabs.com/forge/contributing.html)

## Support

Support for this module is provided by F5.  To file an issue, please visit this [link](https://github.com/f5devcentral/f5-puppet/issues/new)
