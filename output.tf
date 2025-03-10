# SPDX-FileCopyrightText: 2025 Vitaly Karpinsky <realquaker@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

output "vpc_peering_connection_id" {
  description = "Connection Id of VPC Peering"
  value       = aws_vpc_peering_connection.onprem_2_cloud_vpc_peering.id
}

#output "aws_instances" {
# value       = [for instance in aws_instance.this : instance.public_ip]
# description = "Public ips of the instances"
#}
