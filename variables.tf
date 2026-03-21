// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

variable "create" {
  default     = true
  description = "Enable/disable the creation of all resources."
  type        = bool
}

variable "kms_key_arn" {
  default     = null
  description = "ARN of the KMS key to use for encrypting the log group."
  type        = string
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
