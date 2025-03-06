# SPDX-FileCopyrightText: 2025 Vitaly Karpinsky <realquaker@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

variable "ssh_public_key" {
 type        = string
 description = "Path to the public ssh key"
 default     = "~/.ssh/id_rsa.pub"
}
