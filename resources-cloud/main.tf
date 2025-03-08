# SPDX-FileCopyrightText: 2025 Vitaly Karpinsky <realquaker@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

locals {
  # Using Workspaces is just as an example of how to separate envirinments.
  # This feature is not fully implemented.
  instance_type   = terraform.workspace == "prod" ? "t2.large" : "t2.small"
  count           = terraform.workspace == "prod" ? 5 : 3
  ansible_env     = "ANSIBLE_HOST_KEY_CHECKING=False"
  playbook        = "playbook.yml"
  inventory       = "hosts.cfg"
  private_key     = "${var.ssh_private_key}"
}

resource "aws_vpc" "cloud_vpc" {
  cidr_block = "172.16.0.0/16"
  tags = {
    Name = format("%s_%s", "CLOUD_VPC", terraform.workspace)
  }
}

resource "aws_internet_gateway" "cloud_vpc_igw" {
  vpc_id = aws_vpc.cloud_vpc.id

  tags = {
    Name = format("%s_%s", "CLOUD_VPC_IGW", terraform.workspace)
  }
}

resource "aws_subnet" "cloud_public_subnet" {
  vpc_id                  = aws_vpc.cloud_vpc.id
  cidr_block              = "172.16.128.0/20"
  availability_zone       = "eu-central-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = format("%s_%s", "CLOUD_PUBLIC_SUBNET", terraform.workspace)
  }
}

resource "aws_network_acl" "cloud_public_subnet_nacl" {
  vpc_id = aws_vpc.cloud_vpc.id
  subnet_ids = [aws_subnet.cloud_public_subnet.id]

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = format("%s_%s", "CLOUD_PUBLIC_SUBNET_NACL", terraform.workspace)
  }
}

resource "aws_network_acl_association" "cloud_public_subnet_nacl_association" {
  network_acl_id = aws_network_acl.cloud_public_subnet_nacl.id
  subnet_id      = aws_subnet.cloud_public_subnet.id
}

resource "aws_route_table" "cloud_public_subnet_default_rt" {
  vpc_id = aws_vpc.cloud_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloud_vpc_igw.id
  }

  tags = {
    Name = format("%s_%s", "CLOUD_PUBLIC_SUBNET_DEFAULT_RT", terraform.workspace)
  }
}

resource "aws_route_table_association" "cloud_public_subnet_default_rt_association" {
  route_table_id = aws_route_table.cloud_public_subnet_default_rt.id
  subnet_id      = aws_subnet.cloud_public_subnet.id
}

resource "aws_security_group" "cluster_access" {
  vpc_id      = aws_vpc.cloud_vpc.id
  description = "HTTP, HTTPS and SSH Cluster Access"
  name        = format("%s_%s", "CLUSTER_ACCESS", terraform.workspace)

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "cluster" {
  count             = "${local.count}"
  ami               = "ami-03250b0e01c28d196"
  instance_type     = local.instance_type
  key_name          = "UserPublicKey"
  tenancy           = "default"
  subnet_id         = aws_subnet.cloud_public_subnet.id
  security_groups   = ["${aws_security_group.cluster_access.id}"]

  tags = {
     Name = format("%s_%s_%s", "CLUSTER", count.index + 1, terraform.workspace)
  }
}

resource "aws_eip_association" "cluster" {
  count     = "${local.count}"
  instance_id   = "${element(aws_instance.cluster.*.id, count.index)}"
  allocation_id = "${element(aws_eip.cluster.*.id, count.index)}"
}

resource "aws_eip" "cluster" {
  count     = "${local.count}"
  domain    = "vpc"
  instance  = "${element(aws_instance.cluster.*.id, count.index)}"
}

resource "local_file" "cluster_hosts_cfg" {
  content = templatefile("${path.module}/hosts.tpl",
    {
      cluster = aws_eip_association.cluster.*.public_ip
    }
  )
  filename        = "${path.module}/hosts.cfg"
  file_permission = "0644"
}

resource "null_resource" "run_ansible_playbook" {

  depends_on = [aws_instance.cluster, local_file.cluster_hosts_cfg]
  
  provisioner "local-exec" {
    command     = "${local.ansible_env} ansible-playbook -u ubuntu -i ${local.inventory} --private-key ${local.private_key} ${local.playbook}"
    working_dir = path.module
  }
}

# End.
