#!/bin/bash
: ${1?"Usage: $0 SETUP_DIR"}
# thanks SO! https://stackoverflow.com/a/246128
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}/" )/.." >/dev/null 2>&1 && pwd )"
echo "Copying vagrant-hosts-template.yml to $1.yml..."
cp ${ROOT_DIR}/vagrant/vagrant-hosts-template.yml ${ROOT_DIR}/vagrant/$1.yml
echo "Making  ${ROOT_DIR}/vagrant-setups/$1 and creating symlinks..."
mkdir ${ROOT_DIR}/vagrant-setups/$1
ln -s ${ROOT_DIR}/vagrant/Vagrantfile ${ROOT_DIR}/vagrant-setups/$1/Vagrantfile
ln -s ${ROOT_DIR}/vagrant/provisioning ${ROOT_DIR}/vagrant-setups/$1/provisioning
ln -s ${ROOT_DIR}/vagrant/_secrets ${ROOT_DIR}/vagrant-setups/$1/_secrets
ln -s ${ROOT_DIR}/vagrant/ansible.cfg ${ROOT_DIR}/vagrant-setups/$1/ansible.cfg
ln -s ${ROOT_DIR}/vagrant/$1.yml ${ROOT_DIR}/vagrant-setups/$1/vagrant-hosts.yml
echo "Edit ${ROOT_DIR}/vagrant/$1.yml with your setup information"