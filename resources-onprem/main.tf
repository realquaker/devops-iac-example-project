# SPDX-FileCopyrightText: 2025 Vitaly Karpinsky <realquaker@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

locals {
  instance_type = terraform.workspace == "prod" ? "t2.large" : "t2.small"
}

resource "aws_default_vpc" "onprem_vpc" {
  tags = {
    Name = format("%s_%s", "ONPREM_VPC", terraform.workspace)
  }
}

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
    from_port   = 80
    to_port     = 80
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

resource "aws_eip" "eip_jenkins" {
  domain    = "vpc"
  instance  = aws_instance.jenkins.id
}

# End.
