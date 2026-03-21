// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

variable "create" {
  default     = true
  description = "Enable/disable the creation of all resources."
  type        = bool
}

variable "enable_logging" {
  default     = true
  description = "Enable JSON application logging configuration and Powertools logger support for the Lambda function."
  type        = bool
}

variable "enable_powertools_development_mode" {
  default     = false
  description = "Enable Powertools development mode and debug logging for the Lambda function."
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

variable "kms_key_arn" {
  default     = null
  description = "ARN of the KMS key to use for encrypting the log group."
  type        = string
}

variable "log_level" {
  default     = "INFO"
  description = "Application log level for Lambda and Powertools. Valid values: TRACE, DEBUG, INFO, WARN, ERROR, FATAL."
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

variable "tags" {
  default     = {}
  description = "Tags to be applied to all applicable resources."
  type        = map(string)
}
