// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

variable "domain_name" {
  default     = "example.com"
  description = "Domain name served by the static website distribution."
  type        = string
}

variable "email_recipients" {
  default     = ["hello@example.com"]
  description = "List of emails to receive notifications."
  type        = list(string)
}

variable "log_level" {
  default     = "INFO"
  description = "Log level for the Lambda function."
  type        = string
}

variable "log_retention_in_days" {
  default     = 7
  description = "Number of days to retain logs in CloudWatch."
  type        = number
}

variable "ses_source_email" {
  default     = "no-reply@example.com"
  description = "Source email address for SES notifications. Required if email_recipients is not empty."
  type        = string

  validation {
    condition     = var.ses_source_email != null || length(var.email_recipients) == 0
    error_message = "ses_source_email must be provided if email_recipients is not empty."
  }
}
