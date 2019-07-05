## Release 1.9.1
### Summary
This release includes several bug fixes
pull request #61: Add failoverState fact
pull request #60: Update links to aim at extant f5 documentation
pull request #57: Add property for chain certificate to client ssl profile.
pull request #43: sort records in datagroup instances
pull request #30: Allow route domain `%0` to be on end of node names #30

## Release 1.8.0
### Summary
This release includes new F5 features for:
- f5_persistencecookie
- f5_persistencedestaddr
- f5_persistencehash
- f5_persistencesourceaddr
- f5_persistencessl
- f5_persistenceuniversal
- f5_profilehttp
- f5_profileclientssl
- f5_profileserverssl
- f5_sslkey
- f5_sslcertificate
- f5_snat
- f5_snatpool
- f5_datagroup
- f5_datagroupexternal

Updated the design for:
- f5_command

## Release 1.7.0
### Summary
This release adds new resource providers for BIG-IP on-boarding, HA clustering:
- f5_dns
- f5_ntp
- f5_globalsetting
- f5_user
- f5_route
- f5_root
- f5_license
- f5_selfdevice
- f5_device
- f5_addtotrust
- f5_devicegroup
- f5_configsync
- f5_command

## Release 1.5.4
### Summary
This release fixes the `f5_iapp` type to cause changes in the variables of an F5 iApp to trigger a re-deploy of the dependent F5 resources.

### Fixed
- Call 'execute-action' when an `f5_iapp` is modified.

## Release 1.5.3
### Summary
This release fixes an autoload issue related to PUP-6922 in which `f5_selfip` and `f5_pool` require the `f5_node` and cause a "redefine" error.

#### Fixed
- Use alternate API for autoloading f5\_node from f5\_selfip and f5\_pool

## Release 1.5.2
### Summary
This release fixes issues when the f5 module is not in the puppet master or proxy host's modulepath, as well as drastically reducing the number of API calls and handling facts fetching failures.

#### Fixed
- Fix require issues in varying pluginsync environments
- Reduced API calls
- Fix error handling when facts cannot be retrieved (requires admin level)

## Release 1.5.1
### Summary
This is a patch version with several bugfixes.

#### Features/Improvements
- Support for puppet-lint 2.0

#### Bugfixes
- FM-3348: Metadata updated to use puppet gem 
- MODULES-3296: corrects logic for choosing the gem provider
- FM-5424: site.pp creation fix

## Release 1.5.0
### Summary
This feature release adds the `f5_iapp` resource for creating and managing instances of F5 iApp application services.

#### Features/Improvements
- Add `f5_iapp` type

## Release 1.4.1
###Summary

Small release for support of newer PE versions. This increments the version of PE in the metadata.json file.

##2015-10-20 Release 1.4.0
###Summary

Adding 2 new resources selfip and vlan with some minor fixes.

#### Features/Improvements
- selfip resource added
- vlan resource added
- Only display f5_node non-default route domain
- Fix requires in various types
- Test improvements

##2015-07-24 Release 1.3.0
###Summary

Small release for support of newer Puppet versions.

#### Features/Improvements
- Puppet 4 support
- Readme update

##2015-05-21 Release 1.2.0
###Summary

This is a feature release that adds domain routing support. Also includes a bugfix and test cleanup.

####Features
- Adds domain routing support.

####Bugfixes
- Adds fixes to validation and idempotency for all port parameters.

##2015-05-21 Release 1.1.1
###Summary

This bugfix release addresses a bug parsing partition and resource names with a dash in the name.

####Bugfixes
- Fixes handling of dashes in partition and resource names. (e.g. "/partition-name/resource-name")

##2015-05-14 Release 1.1.0
###Summary

This feature release adds the ability to have custom partitions, bugfixes, and numerous test improvements.

####Features
- Add F5 partitions.

####Bugfixes
- Fixes handling dashes in partition name.
- Fix validation of service_port if value is an actual integer.
- Fixes f5 parsing of health monitors set to none.

2015-02-17 Release 1.0.1
This release fixes a bug with the 'none' and 'automap' values for
`f5_virtualserver` `source_address_translation` property

2014-12-18 Release 1.0.0

Initial release.
