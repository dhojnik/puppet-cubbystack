cubbystack
==========

cubbystack is an OpenStack deployment framework for Puppet.

#### Table of Contents

1. [Introduction and Philosophy](#introduction)
  * [History](#history)
  * [Philosophy](#philosophy)
2. [Requirements](#requirements)
3. [Usage](#usage)
  * [Getting Started](#getting-started)
  * [Custom Configurations](#custom-configurations)
  * [Usage Notes](#usage-notes)
4. [Notes](#notes)

## Introduction

### History
cubbystack was created to solve a recurring problem of mine: all of my OpenStack deployments always outgrew the [Puppetlabs OpenStack module](https://forge.puppetlabs.com/puppetlabs/openstack). I began to see that it wasn't just my OpenStack environments, but every production deployment that I came across. The cause varied: it could be something as simple as a single missing option for `nova.conf` or wanting to break Keystone out to its own server.

My initial solution was to compose my own OpenStack module using the individual Puppetlabs OpenStack component modules. This solved some of my issues, but not nearly all of them. For example, if the Glance module didn't have a way for me to configure a certain option, I would either have to patch the module or configure the option outside of the module. The result was a haphazard Frankenstein manifest -- some parts configuring Glance manually and some using the proper module. Not only that, but I was doing this for *each* component and *differently* for each OpenStack environment of mine.

### Philosophy

The first idea of cubbystack is that there will *never* be a one-size-fits-all OpenStack module. It's simply not possible. One could even argue that the very existence of one goes against what makes OpenStack so great: the almost limitless possibilities you have to building an IaaS environment.

cubbystack will assist you in configuring the various OpenStack components, but it will not help you apply them to your environment. For example, cubbystack can install and configure Horizon, but it will not install and configure Apache. That's your responsibility. cubbystack doesn't know or care if you're also running Nagios on the same server as Horizon. Or if you want to use Nginx instead of Apache.

OpenStack can have a lot of dependant components such as KVM, RabbitMQ, MySQL, and memcache. Configuring these components yourself will take some time and effort. But the trade-off is the ability to use the same cubbystack framework with KVM, RabbitMQ, MySQL as Xen, ZeroMQ, and PostgreSQL.

The second idea of cubbystack is that manifest parameters will be kept to a minimum. OpenStack has [a lot](http://docs.openstack.org/havana/config-reference/content/) of configuration options. Configuration options are added and dropped between OpenStack releases. The options that stay between releases can have their default value changed. Translating manifest parameters into these configuration options is not scalable or maintainable. Even the reference tables in the official [guide](http://docs.openstack.org/havana/config-reference/content/) are automatically generated from the OpenStack source code.

It would be great if every OpenStack configuration option could have a corresponding Puppet manifest parameter that has the correct default value and does proper value validation, but I feel that the time and effort involved with doing that is just too much.

Instead, specify your configuration options as a hash:

```yaml
keystone_settings:
  'DEFAULT/verbose': true
  'DEFAULT/syslog':  true
  'token/driver':    'keystone.token.backends.memcache.Token'
```

This gives you the benefit of being able to specify *any* OpenStack configuration option without cubbystack having to know about it as well as benefit of OpenStack automatically using its default value for any value you don't specify.

There are some caveats to this:

1. Sometimes a manifest needs to know about a configuration option. Hence Idea #2 being about *minimum* parameters -- not zero parameters.
2. Each Linux distribution provides its own set of default configuration files. Sometimes the defaults are sane and sometimes not. To help with this, cubbystack can either keep these default values or *purge* them and only use the ones you specify.
3. Knowing what configuration options to use can be hard and intimidating to beginners, but just like the trade-off with having to configure RabbitMQ, KVM, etc, I believe this is well worth the flexibility that is gained in the end.

## Requirements

### The PuppetLabs OpenStack Module Suite

It's a little ironic that an alternative module to the PuppetLabs OpenStack modules requires those exact modules. There's a good reason, though: The PuppetLabs OpenStack modules contain a series of `types` and `providers` to assist with building the various OpenStack configuration files. For example:

```puppet
nova_config { 'DEFAULT/verbose':
  value => true,
}

cinder_config { 'DEFAULT/volume_driver':
  value => 'cinder.volume.drivers.nfs.NfsDriver',
}
```

There's nothing wrong with these types and providers and until I find a better solution or they become incompatible with cubbystack, I'll continue to use them.

#### Side-Note

These types and providers contain a lot of repeated code, though. What'd I'd really like to be able to do is have one master `cubbystack_config` type that works like this:

```puppet
cubbystack_config { '/etc/nova/nova.conf DEFAULT/verbose':
  value => true,
}
```

The benefits of this single `type` include the ability to have configuration files in other directories (such as `/opt` for source-based installs), configuration files with non-standard names (such as `nova-compute.conf`), and automatic support for new OpenStack projects' config files.

Unfortunately such a `type` is not possible with Puppet. The limiting factor would be the inability to `purge` the config file of unmanaged options. This is a deal-breaker to me.

### Puppet

You need to be using Puppet 3.2 or higher in order to take advantage of the iteration functionality.

Hiera is recommended, but not a hard requirement.

## Usage

cubbystack has a set of manifests for almost all OpenStack components (no Quantum at this time). These can be found in the `manifests` directory. Please read and review these manifests -- there's nothing terribly advanced about them, but if you find yourself unable to understand them, I recommend brushing up on Puppet before trying to use this module in production.

All components take a `$settings` parameter. This is a hash of `key => value` settings that ultimately turn into the configuration options for the various OpenStack configuration files. Please see the `examples/settings` directory for samples of hashes.

You can use Hiera or Puppet data types to build your hash -- just as long as what is passed as a parameter is a valid hash.

Please see the `examples/manifests` directory for sample manifests including examples for supporting services.

### Getting Started

I recommend copying the `examples/manifests` directory to a site-local module and then modifying the example manifests to suit your environment.

### Custom Configurations

The whole point of cubbystack is to help create customized OpenStack deployments. For example, here's how to install and configure Keystone two different ways:

Install Keystone and configure it to use a memcache token backend:

```puppet
class { '::cubbystack::keystone':
  settings        => hiera_hash('keystone_settings'),
  admin_password  => 'password',
  purge_resources => false,
}
```

Install Keystone and configure it with a SQL token backend, verbose logging, and directed to syslog:

```puppet
class { '::cubbystack::keystone':
  settings        => hiera_hash('keystone_settings'),
  admin_password  => 'password',
  purge_resources => false,
}
```

As you can see, both class declarations are identical. The difference in configuration comes from the `keystone_settings` hash. For a memcache token backend:

```yaml
keystone_settings:
  'token/driver': 'keystone.token.backends.memcache.Token'
```

And for a SQL token backend, verbose logging, and syslog:

```yaml
keystone_settings:
  'DEFAULT/verbose':             true
  'DEFAULT/use_syslog':          true
  'DEFAULT/syslog_log_facility': 'LOG_LOCAL1'
  'token/driver':                'keystone.token.backends.sql.Token'
```

All other components are configured similarly. If you choose to use Hiera and YAML, you can even combine settings from a `common.yaml` with role-specific settings for a Cloud Controller or Compute Node.

### Usage Notes

#### Horizon

Horizon has to be configured a little differently. While it might be possible to structure the `local_settings.py` file in a YAML-ish way, the support isn't there yet. Instead, I recommend using the example manifest and a static `local_settings.py` file in the `module/files` directory.

#### Swift

Swift support is early and I'm not 100% happy with it. The current working example configuration comes off as too complicated. I hope to have something better soon.

## Notes

* There is no Neutron support at this time. Maybe in a few months.
* As you can see from the manifests, special care has been taken to ensure OpenStack can be installed in a predictable order.
* The name "cubbystack" comes from my son's nickname *Cubby*. I've been surrounded by pictures of bears and cubs lately, so all of my projects are getting prefixed with "cubby".