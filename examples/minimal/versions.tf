// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

terraform {
  required_version = ">= 1.14"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "2.7.1"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "6.37.0"
    }
  }
}
