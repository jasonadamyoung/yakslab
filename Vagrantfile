# -*- mode: ruby -*-
# vi: set ft=ruby :

# Specify minimum Vagrant version and Vagrant API version
Vagrant.require_version ">= 2.2.0"

require 'yaml'
require 'json'
require './vagrant_hosts_maker'

hostgroup = ENV['HOSTGROUP'] ? ENV['HOSTGROUP'] : 'default'
hosts_maker = VagrantHostsMaker.new
vagrant_hosts = hosts_maker.get_host_group(group: hostgroup)

Vagrant.configure("2") do |config|
  vagrant_hosts.each do |vagrant_host|
    box_settings         = vagrant_host["box_settings"]
    provisioner_settings = vagrant_host["provisioner_settings"]
    config.vm.define box_settings['name'] do |provision|

      provision.vm.box = box_settings['box']
      provision.vm.hostname = box_settings['name']
      provision.vm.network box_settings['network'], ip: box_settings['ip_address']

      provision.vm.provider "vmware_desktop" do |v, override|
        v.vmx["memsize"] = box_settings['memory']
        v.vmx["numvcpus"] = box_settings['cpu']
      end

      # see: https://www.vagrantup.com/docs/provisioning/ansible_common.html for documentation on ansible provisioner
      # host provisioning
      provision.vm.provision "ansible" do |ansible|
        ansible.compatibility_mode = "2.0"
        ansible.config_file = "vagrant/ansible.cfg"
        ansible.playbook = "vagrant/provision.yml"
        ansible.extra_vars = provisioner_settings
        ansible.verbose = 'vv'
      end
    end
  end
end
