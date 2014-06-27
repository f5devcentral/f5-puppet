#f5

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with f5](#setup)
    * [What f5 affects](#what-f5-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with f5](#beginning-with-f5)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module provides a number of types and REST based providers to enable
management of LTM F5 loadbalancers.  It supports F5 11.5+ and requires you
to enable the REST endpoint.

## Module Description

This module uses REST to manage various aspects of F5 loadbalancers, and acts
as a foundation for building higher level abstractions within Puppet.

We allow you to manage nodes, pools, in order to manage much of your F5
configuration through Puppet.

## Setup

### What f5 affects

* F5 device configuration.

### Setup Requirements

Currently this module requires you to create a proxy system that is able
to run `puppet device` to further manage the F5.  You'll need to create
a device.conf within Puppet that looks like:

[bigip]
type f5
url https://admin:admin@192.168.1.120/Common

### Beginning with f5

To begin with you can simply call the types from the proxy system we set up
earlier.  You can run puppet resource directly.

```
$ FACTER_url=https://admin:admin@f5.hostname/ puppet resource f5_node
```

You can change a property by hand this way too.

```
$ FACTER_url=https://admin:admin@f5.hostname/ puppet resource f5_user node ensure=absent
```

For further management, as mentioned above, you'll need to create the proxy
system.  Once this is done you can run `puppet device` like `puppet agent` to
have Puppet apply catalogs to your F5.

[TODO:  Fill in details of modelling this in Puppet, probably pulled out
of the previous module.  It's not create but it's better than these
instructions.]

## Usage

You can explore the providers and the options they allow by running puppet
resource `typename` for each type to see what's already on your F5 as a
starting point.  Beyond that all the parameters available for each resource
can be found below.

## Reference

###Global

All resource names are required to be in the format of /Partition/name.

###f5_node

`f5_node` is used to manage nodes on the F5.

####name

The name of the node to manage.

####address

The IP address of the resource.

Valid options: <ipv4|ipv6>

####availability

The availability requirement (number of health monitors) that must be
available.  This must be set if you have any monitors.  If may not be
set to more than the number of monitors you have set.

Valid options: <all|Integer>

####connection_limit

The connection limit of the node.

Valid options: <integer>

####connection_rate_limit

The connection rate limit of the node.

Valid options: <integer>

####description

The description of the node.

Valid options: <String>

####ensure

The ensure state of the node.

Valid options: <present|absent>

####logging

The logging state of the node object.

Valid options:  <disabled|enabled|true|false>

####monitor

The health monitor(s) for the node.  This can be either a single monitor
or an array of monitors.  If you're using an array of monitors then you must
also set availability.

Valid options: <["/Partition/Objects"]|default|none>

####name

The name of the node.

Valid options: <String>

####ratio

The ratio of the node.

Valid options: <integer>

####state

The state of the node.

Valid options: <user-up|user-down>

###f5_pool

`f5_pool` is used to manage pools on the F5.

####Current limitations

* request_queuing requires us to have pool members, and we can't validate that yet.
* pool_member{} is a seperate resource currently so we can't set
  request_queuing to true at pool creation.
* Right now the number of entries ip_encapsulation can have depends on some
  other criteria I don't know yet, so I can't validate how many you can have.

####name

The name of the pool to manage.

####availability

The availability requirement (number of health monitors) that must be
available.  This must be set if you have any monitors.  If may not be
set to more than the number of monitors you have set.

Valid options: <all|Integer>

####monitor

The health monitor(s) for the pool.  This can be either a single monitor
or an array of monitors.  If you're using an array of monitors then you must
also set availability.

Valid options: <["/Partition/Objects"]|default|none>

####description

The description of the pool.

Valid options: <String>

####ensure

The ensure state of the pool.

Valid options: <present|absent>

####allow_snat

[TODO: Figure out better what this does]
Allow SNAT?

Valid options: <true|false>

####allow_nat

[TODO: Figure out better what this does]
Allow NAT?

Valid options: <true|false>

####service_down

Action to take when the service is down.

Valid options: <none|reject|drop|reselect>

####slow_ramp_time

The slow ramp time for the pool.
Valid options: <Integer>

####ip_tos_to_client

The IP TOS to the client.

Valid options: <pass-through|mimic|0-255>

####ip_tos_to_server

The IP TOS to the server.

Valid options: <pass-through|mimic|0-255>

####link_qos_to_client

The Link TOS to the client.

Valid options: <pass-through|0-7>

####link_qos_to_server

The Link TOS to the server.

Valid options: <pass-through|0-7>

####reselect_tries

The number of reselect tries to attempt.

Valid options: <Integer>

####request_queuing

Request Queuing?

Valid options: <true|false>

####request_queue_depth

The request queue depth.

Valid options: <Integer>

####request_queue_timeout

The request queue timeout.

Valid options: <Integer>

####ip_encapsulation

The request queue timeout.

Valid options: </Partition/gre|/Partition/nvgre|/Partition/dslite
  /Partition/ip4ip4|/Partition/ip4ip6|/Partition/ip6ip4|/Partition/ip6ip6
  /Partition/ipip>

####load_balancing_method

The request queue timeout.
Valid options: <round-robin|ratio-member|least-connections-member
  observed-member|predictive-member|ratio-node|least-connection-node
  fastest-node|observed-node|predictive-node|dynamic-ratio-member
  weighted-least-connection-member|weighted-least-connection-node
  ratio-session|ratio-least-connections-member|ratio-least-connection-node>

####ignore_persisted_weight

Ignore persisted weight?

Valid options: <true|false>

####priority_group_activation

The priority group activation (number of nodes) for the pool.

Valid options: <disabled|Integer>

## Limitations

F5: v11.5+.
Puppet Enterprise: v3.3+.

## Development

This is a proprietary module only available to Puppet Enterprise users.  As
such we have no formal way for users to contribute towards development.
However, we know our users are a charming collection of brilliant people and so
if you have a bug you've fixed or contribution to this module please just
generate a diff and throw it into a ticket to support and they'll ensure we get
it.

