// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

variable "cors_allow_origins" {
  default     = ["*"]
  description = "List of allowed origins for CORS."
  type        = list(string)
}

variable "cloudfront_price_class" {
  default     = "PriceClass_100"
  description = "Price class for the CloudFront distribution that fronts the contact form endpoint."
  type        = string

  validation {
    condition = contains([
      "PriceClass_All",
      "PriceClass_200",
      "PriceClass_100",
    ], var.cloudfront_price_class)
    error_message = "cloudfront_price_class must be one of: PriceClass_100, PriceClass_200, PriceClass_All."
  }
}

variable "create" {
  default     = true
  description = "Enable/disable the creation of all resources."
  type        = bool
}

variable "create_cloudfront_distribution" {
  default     = true
  description = "Create a CloudFront distribution in front of the Lambda Function URL so the public endpoint can be protected by AWS WAF and the raw function URL can remain private to CloudFront."
  type        = bool
}

variable "allow_all_cloudfront_distributions" {
  default     = false
  description = "Allow any CloudFront distribution to invoke the Lambda Function URL with SigV4-signed requests. This is useful when integrating with another CloudFront distribution in the same Terraform apply and its ARN is not available yet. Prefer trusted_cloudfront_distribution_arns when possible."
  type        = bool
}

variable "create_waf" {
  default     = true
  description = "Create a secure-by-default AWS WAF web ACL for the public CloudFront distribution. The CloudFront-scope web ACL is managed in us-east-1 internally, as required by AWS."
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

variable "enable_waf_bot_control" {
  default     = false
  description = "Enable the AWS Managed Bot Control rule group on the module-managed WAF. This improves abuse resistance but incurs additional AWS WAF charges."
  type        = bool

  validation {
    condition     = !var.enable_waf_bot_control || var.create_waf
    error_message = "enable_waf_bot_control can only be enabled when create_waf is true."
  }
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

variable "trusted_cloudfront_distribution_arns" {
  default     = []
  description = "Existing CloudFront distribution ARNs that should be allowed to invoke the Lambda Function URL when you are routing contact-form traffic through another distribution, such as unfunco/static-website/aws."
  type        = list(string)

  validation {
    condition = alltrue([
      for arn in var.trusted_cloudfront_distribution_arns :
      can(regex("^arn:[^:]+:cloudfront::[0-9]{12}:distribution/[A-Z0-9]+$", arn))
    ])
    error_message = "trusted_cloudfront_distribution_arns must contain valid CloudFront distribution ARNs."
  }
}

variable "waf_rate_limit" {
  default     = 100
  description = "Maximum number of requests allowed from a single IP address in a rolling 5-minute window before the module-managed AWS WAF blocks it."
  type        = number

  validation {
    condition     = floor(var.waf_rate_limit) == var.waf_rate_limit && var.waf_rate_limit >= 10
    error_message = "waf_rate_limit must be a whole number greater than or equal to 10."
  }
}

variable "waf_web_acl_arn" {
  default     = null
  description = "Existing CLOUDFRONT-scope AWS WAF web ACL ARN to associate with the CloudFront distribution instead of creating one."
  type        = string

  validation {
    condition     = var.waf_web_acl_arn == null || var.create_cloudfront_distribution
    error_message = "waf_web_acl_arn can only be used when create_cloudfront_distribution is true."
  }

  validation {
    condition = (
      var.waf_web_acl_arn == null ||
      can(regex("^arn:[^:]+:wafv2:us-east-1:[0-9]{12}:global/webacl/.+$", var.waf_web_acl_arn))
    )
    error_message = "waf_web_acl_arn must be a CLOUDFRONT-scope WAFv2 web ACL ARN in us-east-1."
  }
}
