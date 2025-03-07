# SPDX-FileCopyrightText: 2025 Vitaly Karpinsky <realquaker@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

output "vpc_id" {
  value = aws_default_vpc.onprem_vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.onprem_public_subnet.id
}

output "security_group_id" {
  value = aws_security_group.jenkins_access.id
}

output "jenkins_server_primary_ip" {
  value = aws_instance.jenkins.public_ip
}


output "jenkins_server_private_ip" {
  value = aws_instance.jenkins.private_ip
}

# End.
