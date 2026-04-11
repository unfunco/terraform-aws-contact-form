// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

output "contact_form_url" {
  description = "Contact form path routed through the website distribution."
  value       = format("https://%s/contact", var.domain_name)
}

output "website_cloudfront_domain_name" {
  description = "CloudFront domain name for the website distribution."
  value       = module.website.cloudfront_domain_name
}
