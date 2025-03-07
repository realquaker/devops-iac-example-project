# SPDX-FileCopyrightText: 2025 Vitaly Karpinsky <realquaker@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

output "vpc_id" {
  value = aws_vpc.cloud_vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.cloud_public_subnet.id
}

output "security_group_id" {
  value = aws_security_group.cluster_access.id
}

output "cluster_server_primary_ip" {
  value = aws_instance.cluster[*].public_ip
}


output "cluster_server_private_ip" {
  value = aws_instance.cluster[*].private_ip
}

# End.
