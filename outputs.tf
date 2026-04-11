// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution that fronts the contact form endpoint."
  value       = try(aws_cloudfront_distribution.this[0].arn, null)
}

output "cloudfront_origin_access_control_id" {
  description = "CloudFront origin access control ID for securely using the Lambda Function URL as an origin in another CloudFront distribution, such as unfunco/static-website/aws."
  value       = try(aws_cloudfront_origin_access_control.this[0].id, null)
}

output "cloudfront_origin_domain_name" {
  description = "Domain name to use when wiring the Lambda Function URL into another CloudFront distribution as a custom origin."
  value       = local.lambda_url_domain_name
}

output "cloudfront_origin_request_policy_id" {
  description = "CloudFront origin request policy ID that forwards viewer headers except Host, suitable for Lambda Function URL origins."
  value       = try(data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header[0].id, null)
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name for the public contact form endpoint."
  value       = try(aws_cloudfront_distribution.this[0].domain_name, null)
}

output "cloudfront_cache_policy_id" {
  description = "CloudFront cache policy ID that disables caching for the contact form endpoint."
  value       = try(data.aws_cloudfront_cache_policy.caching_disabled[0].id, null)
}

output "endpoint_url" {
  description = "Public URL to use for contact form submissions when this module manages the public endpoint itself. This is the CloudFront URL when the distribution is enabled; otherwise it falls back to the raw Lambda Function URL only when that URL is public."
  value = try(
    var.create_cloudfront_distribution ? format("https://%s", aws_cloudfront_distribution.this[0].domain_name) : local.function_url_auth_type == "NONE" ? aws_lambda_function_url.this[0].function_url : null,
    null,
  )
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function."
  value       = try(aws_lambda_function.this[0].arn, null)
}

output "lambda_function_name" {
  description = "Name of the Lambda function."
  value       = try(aws_lambda_function.this[0].function_name, null)
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role."
  value       = try(aws_iam_role.this[0].arn, null)
}

output "lambda_url" {
  description = "Lambda Function URL used as the CloudFront origin. When this module manages CloudFront or trusted_cloudfront_distribution_arns is set, this URL requires IAM-signed requests and is not intended for browsers."
  value       = try(aws_lambda_function_url.this[0].function_url, null)
}

output "log_group_name" {
  description = "Name of the CloudWatch log group used by the Lambda function."
  value       = try(aws_cloudwatch_log_group.this[0].name, null)
}

output "waf_web_acl_arn" {
  description = "ARN of the AWS WAF web ACL created or used for the public CloudFront endpoint, whether that distribution is managed here or by another module."
  value       = local.cloudfront_web_acl_arn
}
