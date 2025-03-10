# SPDX-FileCopyrightText: 2025 Vitaly Karpinsky <realquaker@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

resource "aws_key_pair" "tf_key" {
  key_name   = "UserPublicKey"
  public_key = file("${var.ssh_public_key}")
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "vault" {
  description             = "An Vaulte KMS key"
  enable_key_rotation     = false
}

# resource "aws_kms_key_policy" "vault" {
#   key_id = aws_kms_key.vault.id
#   policy = jsonencode({
#     Version = "2025-03-09"
#     Id      = "key-vault-1"
#     Statement = [
#       {
#         Sid    = "Enable IAM User Permissions"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#         },
#         Action   = "kms:*"
#         Resource = "*"
#       }
#     ]
#   })
# }

module "resources-onprem" {
  source = "./resources-onprem"
  vpc_id = module.resources-onprem.vpc_id
}

module "resources-cloud" {
  source = "./resources-cloud"
  vpc_id = module.resources-cloud.vpc_id
}

resource "aws_vpc_peering_connection" "onprem_2_cloud_vpc_peering" {
  vpc_id      = module.resources-onprem.vpc_id
  peer_vpc_id = module.resources-cloud.vpc_id
  auto_accept = true
}

resource "aws_route" "route_2_cloud" {
  route_table_id = module.resources-onprem.onprem_rt_id
  destination_cidr_block = "172.16.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.onprem_2_cloud_vpc_peering.id
}

resource "aws_route" "route_2_onprem" {
  route_table_id = module.resources-cloud.cloud_rt_id
  destination_cidr_block = "172.21.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.onprem_2_cloud_vpc_peering.id
}

# End.
