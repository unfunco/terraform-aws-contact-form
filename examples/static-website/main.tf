// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

provider "aws" {}

module "contact_form" {
  source = "../.."

  name                           = format("%s-contact-form", replace(var.domain_name, ".", "-"))
  create_cloudfront_distribution = false

  # This keeps the example usable in a single apply while the website
  # distribution is being created below.
  allow_all_cloudfront_distributions = true

  cors_allow_origins = [
    format("https://%s", var.domain_name),
  ]

  email_recipients      = var.email_recipients
  log_level             = var.log_level
  log_retention_in_days = var.log_retention_in_days
  ses_source_email      = var.ses_source_email
}

module "website" {
  source  = "unfunco/static-website/aws"
  version = "0.5.0"

  domain_name           = var.domain_name
  cloudfront_web_acl_id = module.contact_form.waf_web_acl_arn

  cloudfront_additional_origins = {
    contact_form = {
      domain_name              = module.contact_form.cloudfront_origin_domain_name
      origin_access_control_id = module.contact_form.cloudfront_origin_access_control_id
    }
  }

  cloudfront_ordered_cache_behaviors = [
    {
      path_pattern             = "/contact"
      allowed_methods          = ["OPTIONS", "POST"]
      cached_methods           = ["OPTIONS"]
      cache_policy_id          = module.contact_form.cloudfront_cache_policy_id
      origin_request_policy_id = module.contact_form.cloudfront_origin_request_policy_id
      target_origin_id         = "contact_form"
    },
  ]
}
