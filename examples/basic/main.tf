// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

provider "aws" {}

module "contact_form" {
  source = "../.."

  enable_tracing        = true
  email_recipients      = var.email_recipients
  log_level             = var.log_level
  log_retention_in_days = var.log_retention_in_days
  ses_source_email      = var.ses_source_email
}
