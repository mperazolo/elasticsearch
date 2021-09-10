#!/bin/bash

sudo yum -y install make rpm-build gpg
sudo yum -y install java-11-openjdk-devel
echo "% _binaries_in_noarch_packages_terminate_build 0" | sudo tee /etc/rpm/macros
