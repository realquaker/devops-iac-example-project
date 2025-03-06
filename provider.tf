# SPDX-FileCopyrightText: 2025 Vitaly Karpinsky <realquaker@gmail.com>
# SPDX-License-Identifier: GPL-2.0-or-later

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.89"
    }
  }
}

provider "aws" {
    profile                     = "default"
#   region                      = "eu-central-1"
    shared_config_files         = ["$HOME/.aws/config"]
    shared_credentials_files    = ["$HOME/.aws/credentials"]

}

# End.
