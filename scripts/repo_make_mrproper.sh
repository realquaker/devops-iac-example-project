#!/usr/bin/bash

# SPDX-FileCopyrightText: 2025 Vitaly Karpinsky <realquaker@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

echo -e "This script will delete the current configuration and all generated files.";
echo -e "Including Terraform state files.";
read -p "Are you sure? (N/y): " respond && [[ $respond == [yY] || $respond == [yY][eE][sS] ]] || exit 1;

TRASH="\
../.terraform.lock.hcl
../.terraform/

";


echo -e "Yes!";
