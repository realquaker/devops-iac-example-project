#!/usr/bin/bash

# SPDX-FileCopyrightText: 2025 Vitaly Karpinsky <realquaker@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

PKGS="curl gpg software-properties-common snapd";

echo -e "This script will install Terraform and Ansible on this Ubuntu host.";
echo -e "No other Linux distributions were tested yet."
echo -e "It will add APT Repos for both Terraform and Ansible.";
read -p "Do you want to continue? (N/y): " respond && [[ $respond == [yY] || $respond == [yY][eE][sS] ]] || exit 1;

# Check if user is root or sudo is installed if not.
if [ ! -x /usr/bin/sudo ];
  then
    echo -e "Seems like sudo is NOT installed.";
    echo -e "Install sudo and run this script again.";
    exit 1;
fi

InstallTools() {
    sudo sh -c "apt update; apt install ${PKGS}"
}

InstallAnsible() {
    sudo sh -c "add-apt-repository --yes --update ppa:ansible/ansible; apt install -y ansible";
}

InstallTerraform() {
    sudo sh -c "\
    curl https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp.gpg;
    echo \"deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\" > /etc/apt/sources.list.d/hashicorp.list;
    apt update; apt install -y terraform;"
}

InstallAWScli() {
    sudo sh -c "\
    snap refresh;
    snap install aws-cli --classic;
    snap install amazon-ssm-agent --classic;"
}

InstallTools;
InstallAnsible;
InstallTerraform;
InstallAWScli;

# End.
