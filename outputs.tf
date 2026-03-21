// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

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
  description = "Public Lambda Function URL."
  value       = try(aws_lambda_function_url.this[0].function_url, null)
}

output "log_group_name" {
  description = "Name of the CloudWatch log group used by the Lambda function."
  value       = try(aws_cloudwatch_log_group.this[0].name, null)
}
