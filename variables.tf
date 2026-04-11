// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

variable "cors_allow_origins" {
  default     = ["*"]
  description = "List of allowed origins for CORS."
  type        = list(string)
}

variable "create" {
  default     = true
  description = "Enable/disable the creation of all resources."
  type        = bool
}

variable "email_recipients" {
  default     = []
  description = "List of emails to receive notifications. Requires ses_source_email when not empty."
  type        = list(string)

  validation {
    condition = alltrue([
      for email in var.email_recipients : can(regex("^[^@\\s]+@[^@\\s]+$", email))
    ])
    error_message = "email_recipients must contain valid email addresses."
  }
}

variable "email_template" {
  default     = null
  description = "Custom HTML email template content. Use $field_name or $fields_html for variable substitution with form values. When null, the default template is used."
  type        = string
}

variable "enable_logging" {
  default     = true
  description = "Enable JSON application logging configuration and Powertools logger support for the Lambda function."
  type        = bool
}

variable "enable_powertools_development_mode" {
  default     = false
  description = "Enable Powertools development mode, debug logging, and Powertools event logging for the Lambda function."
  type        = bool
}

variable "enable_tracing" {
  default     = false
  description = "Enable AWS X-Ray tracing and Powertools tracer support for the Lambda function."
  type        = bool
}

variable "environment_variables" {
  default     = {}
  description = "Additional environment variables to set on the Lambda function."
  type        = map(string)
}

variable "fields" {
  default = [
    { name = "name", type = "text" },
    { name = "email", type = "email" },
    { name = "message", type = "textarea" },
  ]
  description = "List of form fields to accept and validate. Supported types: text, email, textarea."
  type = list(object({
    name = string
    type = string
  }))

  validation {
    condition     = length(var.fields) > 0
    error_message = "At least one field must be defined."
  }

  validation {
    condition = alltrue([
      for field in var.fields : contains(["text", "email", "textarea"], field.type)
    ])
    error_message = "Field type must be one of: text, email, textarea."
  }

  validation {
    condition     = length(var.fields) == length(distinct([for field in var.fields : field.name]))
    error_message = "Field names must be unique."
  }

  validation {
    condition = alltrue([
      for field in var.fields : can(regex("^[a-z][a-z0-9_]*$", field.name))
    ])
    error_message = "Field names must start with a lowercase letter and contain only lowercase letters, digits, and underscores."
  }
}

variable "kms_key_arn" {
  default     = null
  description = "ARN of the KMS key to use for encrypting the log group."
  type        = string
}

variable "log_level" {
  default     = "INFO"
  description = "Application log level for Lambda and Powertools. Valid values: TRACE, DEBUG, INFO, WARN, ERROR, FATAL. DEBUG also enables Powertools event logging."
  nullable    = false
  type        = string

  validation {
    condition     = contains(["TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL"], upper(var.log_level))
    error_message = "log_level must be one of: TRACE, DEBUG, INFO, WARN, ERROR, FATAL."
  }
}

variable "log_retention_in_days" {
  default     = 365
  description = "Number of days to retain logs in CloudWatch Log Group."
  type        = number
}

variable "memory_size" {
  default     = 128
  description = "Amount of memory, in MB, allocated to the Lambda function."
  type        = number
}

variable "name" {
  default     = "contact-form"
  description = "Name to use for the Lambda function and related resources."
  type        = string
}

variable "ses_source_email" {
  default     = null
  description = "Verified SES sender address used for notifications. Required when email_recipients is not empty."
  type        = string

  validation {
    condition     = var.ses_source_email == null || can(regex("^[^@\\s]+@[^@\\s]+$", var.ses_source_email))
    error_message = "ses_source_email must be a valid email address when set."
  }

  validation {
    condition     = !var.create || length(var.email_recipients) == 0 || var.ses_source_email != null
    error_message = "ses_source_email must be set when email_recipients is not empty."
  }
}

variable "tags" {
  default     = {}
  description = "Tags to be applied to all applicable resources."
  type        = map(string)
}
