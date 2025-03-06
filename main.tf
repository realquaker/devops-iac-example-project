# SPDX-FileCopyrightText: 2025 Vitaly Karpinsky <realquaker@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

resource "aws_key_pair" "tf_key" {
  key_name   = "UserPublicKey"
  public_key = file("~/.ssh/id_rsa.pub")
}

module "resources-onprem" {
  source = "./resources-onprem"
  vpc_id = module.resources-onprem.vpc_id
}

#module "resources-cloud" {
#  source = "./resources-cloud"
#  vpc_id = module.network-resources.vpc_id
#}s

#module "ec2-resources" {
#  source = "./ec2-resources"

#  vpc_id = module.network-resources.vpc_id
#  security_group_id = module.security-resources.security_group_id
#  public_subnet_id = module.network-resources.public_subnet_id

#}


# End.
