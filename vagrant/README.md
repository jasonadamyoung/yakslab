# Vagrant Test Configuration

This repository includes a customized Vagrantfile and a "Hosts Maker" ruby library that allows it to be used for *multiple* "setups" for creating multi-machine sets for testing.

## Background

Vagrant is really designed to use a [Vagrantfile _per_ machine](https://www.vagrantup.com/docs/vagrantfile) or [set of machines](https://www.vagrantup.com/docs/multi-machine)

However, my use case is a bunch of independent "setups" to install GitLab test instances. I didn't want to create multiple Vagrantfiles, with the same settings over and over for each setup.

I had the following goals:

* Minimal configuration settings for each "setup" (group of hosts)
* Programmatic logic to expand each "setup" into the vagrant box and provisioner (I'm using Ansbile) settings.
* Programmatic logic to set IP Address and host name for each host.
* Programmatic logic to determine the latest GitLab version (so I didn't have to keep updating the configuration file for every GitLab release)

And some amount of over-engineering (and way too much repetitive hash walking) later, the `VagrantHostsMaker` emerged. Essentially it's a dynamic inventory builder for Vagrant/Vagrant Ansible provisioning.

## How it works

Vagrant's [Vagrantfile](https://www.vagrantup.com/docs/vagrantfile) is written in and interpreted as Ruby - so `VagrantHostsMaker` is a set of Ruby classes included by the Vagrantfile that uses only the built-in Ruby standard libraries.

### GitLab version expansion

I have [written other code](https://gitlab.com/rambleon/yakslab/-/blob/main/yakslib/labtools/releases/gitlab.rb) that uses the GitLab API to pull GitLab Release and Tag information. I thought about importing this code into the HostsMaker - but run into trouble requring other Gems other than the ones that are part of Vagrant. This probably belongs in a Vagrant plugin - but to maintain the ability to just use the standard libraries for now - the Version information for GitLab (and K3s) comes from a couple of yaml files: [GitLab](cached_gitlab_tag_info.yml) and [K3s](cached_k3s_release_info.yml).

These are actually maintained by a dedicated GitLab CI/CD project (on a non-GitLab.com test instance) - that's running a daily [scheduled pipeline](https://gitlab.com/jayo/glops-cacher/-/pipelines) to keep the tag/relese information updated.

### IP Allocator

This currently assumes a VMWare configuration, but the [IPAllocator](./hosts_maker/ip_allocator.rb) is a mostly-dumb script to get the VMWare subnet for the host and the range not in use by the VMWare DHCP server - and creates a "cache file" of IP <-> Host name mappings, so that I have a known IP Address to use for the [vagrant-hostsupdater](https://github.com/agiledivider/vagrant-hostsupdater) plugin to manage `/etc/hosts` for the host:ip pair.

There are some limitations here - but it's a first iteration of IP reservations so that I have a known IP address for both the vagrant-hostsupdater plugin and for provisioning

### Caveats:

* The script will allocate IP Addresses by hostname
* It doesn't clean up after itself
* It re-uses the IP by hostname - so if a host in another host group ends up named the same - there could be a name conflict. It's expected that vm's will be halted and/or destroyed when switching between host groups

### Configuration expansion

This is the core purpose of `VagrantHostsMaker`: to logically expand a "setup" to a set of box, provisioner, and global Ansible settings.

There are currently classes to handle a "generic" host, various GitLab configurations, and a simple three-host [k3s cluster](https://k3s.io/) for kubernetes testing.

For example - `VagrantHostsMaker` will turn this ([example gitlab-gitlab config](./gitlab-gitaly.yml) in combination with the [defaults](./vagrant-hosts-defaults.yml)):

```yaml
---
hosts:
  - gitlab:
      version: latest
      hosts:
        app:
        gitaly:
```

Into this:  (the [hosts_and_groups.rb](./hosts_and_groups.rb) script will generate this output for debugging)

**Hosts:**

```json
[
  {
    "box_settings": {
      "name": "gitlab-app-latest.gldev",
      "box": "bento/ubuntu-20.04",
      "network": "private_network",
      "memory": 4096,
      "cpu": 4,
      "ip_address": "192.168.67.5"
    },
    "provisioner_settings": {
      "gitlab_external_url": "http://gitlab-app-latest.gldev",
      "gitlab_app_primary": "gitlab-app-latest.gldev",
      "gitlab_ip_address": "192.168.67.5",
      "gitlab_version": "13.5.3",
      "gitlab_edition": "ee",
      "gitlab_external_gitaly": true,
      "gitlab_roles": "all"
    },
    "ansible_settings": {
      "verbosity": "v",
      "playbook": "provisioning/gitlab.yml"
    }
  },
  {
    "box_settings": {
      "name": "gitlab-gitaly-latest.gldev",
      "box": "bento/ubuntu-20.04",
      "network": "private_network",
      "memory": 4096,
      "cpu": 4,
      "ip_address": "192.168.67.6"
    },
    "provisioner_settings": {
      "gitlab_external_url": "http://gitlab-app-latest.gldev",
      "gitlab_app_primary": "gitlab-app-latest.gldev",
      "gitlab_ip_address": "192.168.67.6",
      "gitlab_version": "13.5.3",
      "gitlab_edition": "ee",
      "gitlab_external_gitaly": true,
      "gitlab_roles": "gitaly"
    },
    "ansible_settings": {
      "verbosity": "v",
      "playbook": "provisioning/gitlab.yml"
    }
  }
]
```

**Groups:**

```yaml
---
gitlab:
- gitlab-app-latest.gldev
- gitlab-gitaly-latest.gldev
gitlab_app:
- gitlab-app-latest.gldev
gitlab_app_primary:
- gitlab-app-latest.gldev
gitlab_gitaly:
- gitlab-gitaly-latest.gldev
```

Separated setups are achieved by putting each "setup" in their own directory - symlinking the Vagrantfile, Host Maker modules, and Ansible roles/playbooks/configuration.

A [shell script](./make-vagrant-setup.sh) is included that will create a "setup directory":

```
$ tree vagrant-setups/
vagrant-setups/
├── gitlab-gitaly
│   ├── Vagrantfile -> /Users/jayo/dev/glops/vagrant/Vagrantfile
│   ├── _secrets -> /Users/jayo/dev/glops/vagrant/_secrets
│   ├── ansible.cfg -> /Users/jayo/dev/glops/vagrant/ansible.cfg
│   ├── gitlab-app-latest.gldev.initialprovision
│   ├── provisioning -> /Users/jayo/dev/glops/vagrant/provisioning
│   └── vagrant-hosts.yml -> /Users/jayo/dev/glops/vagrant/gitlab-gitaly.yml
[...]
```

### Vagrantfile tricks

One of the drawbacks of using [Ansible auto-generated inventory](https://www.vagrantup.com/docs/provisioning/ansible_intro#auto-generated-inventory) is that Vagrant will not build the `.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory` until provisioning triggers for *all* the machines the first time through.  This means that you cannot rely on a full inventory (especially groups) at `vagrant up` time - without using the [Ansible parallel execution trick](https://www.vagrantup.com/docs/provisioning/ansible#ansible-parallel-execution) - which I don't want to do because I need the primary GitLab application to be up and configured for scaled setups, or even just GitLab runner.

So I'm making use of [Vagrant triggers](https://www.vagrantup.com/docs/triggers) to inject an ["Initial Playbook"](./provisioning/vagrant_initial_provision.yml) after the first `vagrant up` - after that `vagrant provision` will work normally.

See the [Vagrantfile](./Vagrantfile) comments for more details.

