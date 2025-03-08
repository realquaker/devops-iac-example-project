# SPDX-FileCopyrightText: 2025 Vitaly Karpinsky <realquaker@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

locals {
  # Using Workspaces is just as an example of how to separate envirinments.
  # This feature is not fully implemented.
  instance_type   = terraform.workspace == "prod" ? "t2.large" : "t2.small"
  ansible_env     = "ANSIBLE_HOST_KEY_CHECKING=False"
  playbook        = "playbook.yml"
  inventory       = "hosts.cfg"
  private_key     = "${var.ssh_private_key}"
}

# We will use AWS Default VPC as On Prem Environment
resource "aws_default_vpc" "onprem_vpc" {
  tags = {
    Name = format("%s_%s", "ONPREM_VPC", terraform.workspace)
  }
}

# not needed for default vpc
#resource "aws_internet_gateway" "onprem_vpc_igw" {
#  vpc_id = aws_default_vpc.onprem_vpc.id

#  tags = {
#    Name = format("%s_%s", "ONPREM_VPC_IGW", terraform.workspace)
#  }
#}

resource "aws_subnet" "onprem_public_subnet" {
  vpc_id                  = aws_default_vpc.onprem_vpc.id
  cidr_block              = "172.31.128.0/20"
  availability_zone       = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = format("%s_%s", "ONPREM_PUBLIC_SUBNET", terraform.workspace)
  }
}

resource "aws_network_acl" "onprem_public_subnet_nacl" {
  vpc_id = aws_default_vpc.onprem_vpc.id
  subnet_ids = [aws_subnet.onprem_public_subnet.id]

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
    Name = format("%s_%s", "ONPREM_PUBLIC_SUBNET_NACL", terraform.workspace)
  }
}

resource "aws_network_acl_association" "onprem_public_subnet_nacl_association" {
  network_acl_id = aws_network_acl.onprem_public_subnet_nacl.id
  subnet_id      = aws_subnet.onprem_public_subnet.id
}

# not needed for default vpc
#resource "aws_route_table" "onprem_public_subnet_default_rt" {
#  vpc_id = aws_default_vpc.onprem_vpc.id

#  route {
#    cidr_block = "0.0.0.0/0"
#    gateway_id = aws_internet_gateway.onprem_vpc_igw.id
#  }

#  tags = {
#    Name = format("%s_%s", "ONPREM_PUBLIC_SUBNET_DEFAULT_RT", terraform.workspace)
#  }
#}

#resource "aws_route_table_association" "onprem_public_subnet_default_rt_association" {
#  route_table_id = aws_route_table.onprem_public_subnet_default_rt.id
#  subnet_id      = aws_subnet.onprem_public_subnet.id
#}

resource "aws_security_group" "jenkins_access" {
  vpc_id      = aws_default_vpc.onprem_vpc.id
  description = "HTTP and SSH Jenkins Access"
  name        = format("%s_%s", "JENKINS_ACCESS", terraform.workspace)

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "8080"
    to_port     = "8080"
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

resource "aws_instance" "jenkins" {
  ami               = "ami-03250b0e01c28d196"
  instance_type     = local.instance_type
  key_name          = "UserPublicKey"
  tenancy           = "default"
  subnet_id         = aws_subnet.onprem_public_subnet.id
  security_groups   = ["${aws_security_group.jenkins_access.id}"]

  tags = {
     Name = format("%s_%s", "JENKINS", terraform.workspace)
  }
}

resource "aws_eip_association" "jenkins" {
  instance_id   = aws_instance.jenkins.id
  allocation_id = aws_eip.jenkins.id
}

resource "aws_eip" "jenkins" {
  domain    = "vpc"
  instance  = aws_instance.jenkins.id
}

resource "local_file" "jenkins_hosts_cfg" {
  content = templatefile("${path.module}/hosts.tpl",
    {
      jenkins = aws_eip_association.jenkins.*.public_ip
    }
  )
  filename        = "${path.module}/hosts.cfg"
  file_permission = "0644"
}

resource "null_resource" "run_ansible_playbook" {
  
  depends_on = [aws_instance.jenkins, local_file.jenkins_hosts_cfg]

  provisioner "local-exec" {
    command     = "${local.ansible_env} ansible-playbook -u ubuntu -i ${local.inventory} --private-key ${local.private_key} ${local.playbook}"
    working_dir = path.module
  }
}

# End.
