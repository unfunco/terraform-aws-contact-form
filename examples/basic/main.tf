// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

provider "aws" {}

module "contact_form" {
  source = "../.."

  enable_tracing        = true
  email_recipients      = ["hidden@example.com"]
  log_level             = "DEBUG"
  log_retention_in_days = 7
  ses_source_email      = "no-reply@example.com"
}
