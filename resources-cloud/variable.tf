# SPDX-FileCopyrightText: 2025 Vitaly Karpinsky <realquaker@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

variable "vpc_id" {
  type = string
}

variable "ssh_private_key" {
 type        = string
 description = "Path to the private ssh key"
 default     = "~/.ssh/id_rsa"
}

# End.
