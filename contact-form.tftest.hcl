// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

mock_provider "archive" {}
mock_provider "aws" {}
mock_provider "aws" {
  alias = "us_east_1"
}

run "kebab_case_name_produces_kebab_case_suffixes" {
  command = plan

  variables {
    name = "contact-form"
  }

  override_data {
    target = data.aws_caller_identity.this[0]
    values = {
      account_id = "123456789012"
    }
  }

  override_data {
    target = data.aws_partition.this[0]
    values = {
      dns_suffix = "amazonaws.com"
      partition  = "aws"
    }
  }

  override_data {
    target = data.aws_region.this[0]
    values = {
      region = "eu-west-2"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.assume_role[0]
    values = {
      json = <<JSON
      {
        "Version": "2012-10-17",
        "Statement": []
      }
      JSON
    }
  }

  override_data {
    target = data.aws_iam_policy_document.this[0]
    values = {
      json = <<JSON
      {
        "Version": "2012-10-17",
        "Statement": []
      }
      JSON
    }
  }

  override_data {
    target = data.aws_cloudfront_cache_policy.caching_disabled[0]
    values = {
      id = "managed-caching-disabled"
    }
  }

  override_data {
    target = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header[0]
    values = {
      id = "managed-all-viewer-except-host-header"
    }
  }

  assert {
    condition     = aws_iam_role.this[0].name == "contact-form-lambda"
    error_message = "Expected role name 'contact-form-lambda', got '${aws_iam_role.this[0].name}'."
  }

  assert {
    condition     = aws_iam_role_policy.this[0].name == "contact-form-execution"
    error_message = "Expected policy name 'contact-form-execution', got '${aws_iam_role_policy.this[0].name}'."
  }

  assert {
    condition     = aws_lambda_function_url.this[0].authorization_type == "AWS_IAM"
    error_message = "Expected the default function URL authorization type to be 'AWS_IAM'."
  }

  assert {
    condition     = aws_wafv2_web_acl.this[0].scope == "CLOUDFRONT"
    error_message = "Expected the default WAF scope to be 'CLOUDFRONT'."
  }

  assert {
    condition     = length(aws_lambda_permission.function_url_cloudfront_managed) == 1
    error_message = "Expected exactly one CloudFront-scoped Lambda Function URL permission by default."
  }
}

run "pascal_case_name_produces_pascal_case_suffixes" {
  command = plan

  variables {
    name = "ContactForm"
  }

  override_data {
    target = data.aws_caller_identity.this[0]
    values = {
      account_id = "123456789012"
    }
  }

  override_data {
    target = data.aws_partition.this[0]
    values = {
      dns_suffix = "amazonaws.com"
      partition  = "aws"
    }
  }

  override_data {
    target = data.aws_region.this[0]
    values = {
      region = "eu-west-2"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.assume_role[0]
    values = {
      json = <<JSON
      {
        "Version": "2012-10-17",
        "Statement": []
      }
      JSON
    }
  }

  override_data {
    target = data.aws_iam_policy_document.this[0]
    values = {
      json = <<JSON
      {
        "Version": "2012-10-17",
        "Statement": []
      }
      JSON
    }
  }

  override_data {
    target = data.aws_cloudfront_cache_policy.caching_disabled[0]
    values = {
      id = "managed-caching-disabled"
    }
  }

  override_data {
    target = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header[0]
    values = {
      id = "managed-all-viewer-except-host-header"
    }
  }

  assert {
    condition     = aws_iam_role.this[0].name == "ContactFormLambda"
    error_message = "Expected role name 'ContactFormLambda', got '${aws_iam_role.this[0].name}'."
  }

  assert {
    condition     = aws_iam_role_policy.this[0].name == "ContactFormExecution"
    error_message = "Expected policy name 'ContactFormExecution', got '${aws_iam_role_policy.this[0].name}'."
  }

  assert {
    condition     = length(aws_lambda_permission.function_url_cloudfront_managed_invoke) == 1
    error_message = "Expected default function URL invoke permissions to be limited to CloudFront."
  }
}

run "disabling_cloudfront_restores_public_function_url" {
  command = plan

  variables {
    create_cloudfront_distribution = false
    create_waf                     = false
  }

  override_data {
    target = data.aws_caller_identity.this[0]
    values = {
      account_id = "123456789012"
    }
  }

  override_data {
    target = data.aws_partition.this[0]
    values = {
      dns_suffix = "amazonaws.com"
      partition  = "aws"
    }
  }

  override_data {
    target = data.aws_region.this[0]
    values = {
      region = "eu-west-2"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.assume_role[0]
    values = {
      json = <<JSON
      {
        "Version": "2012-10-17",
        "Statement": []
      }
      JSON
    }
  }

  override_data {
    target = data.aws_iam_policy_document.this[0]
    values = {
      json = <<JSON
      {
        "Version": "2012-10-17",
        "Statement": []
      }
      JSON
    }
  }

  assert {
    condition     = aws_lambda_function_url.this[0].authorization_type == "NONE"
    error_message = "Expected the function URL to remain public when CloudFront is disabled."
  }

  assert {
    condition     = length(aws_cloudfront_distribution.this) == 0
    error_message = "Expected no CloudFront distribution when create_cloudfront_distribution is false."
  }

  assert {
    condition     = length(aws_lambda_permission.function_url_public) == 1
    error_message = "Expected the public Lambda Function URL permission when CloudFront protection is disabled."
  }
}

run "external_cloudfront_distribution_arns_keep_function_url_private" {
  command = plan

  variables {
    create_cloudfront_distribution       = false
    trusted_cloudfront_distribution_arns = ["arn:aws:cloudfront::123456789012:distribution/E123456789ABC"]
  }

  override_data {
    target = data.aws_caller_identity.this[0]
    values = {
      account_id = "123456789012"
    }
  }

  override_data {
    target = data.aws_partition.this[0]
    values = {
      dns_suffix = "amazonaws.com"
      partition  = "aws"
    }
  }

  override_data {
    target = data.aws_region.this[0]
    values = {
      region = "eu-west-2"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.assume_role[0]
    values = {
      json = <<JSON
      {
        "Version": "2012-10-17",
        "Statement": []
      }
      JSON
    }
  }

  override_data {
    target = data.aws_iam_policy_document.this[0]
    values = {
      json = <<JSON
      {
        "Version": "2012-10-17",
        "Statement": []
      }
      JSON
    }
  }

  override_data {
    target = data.aws_cloudfront_cache_policy.caching_disabled[0]
    values = {
      id = "managed-caching-disabled"
    }
  }

  override_data {
    target = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header[0]
    values = {
      id = "managed-all-viewer-except-host-header"
    }
  }

  assert {
    condition     = aws_lambda_function_url.this[0].authorization_type == "AWS_IAM"
    error_message = "Expected trusted CloudFront distributions to keep the function URL private to CloudFront."
  }

  assert {
    condition     = length(aws_cloudfront_origin_access_control.this) == 1
    error_message = "Expected an origin access control to be created for external CloudFront integration."
  }

  assert {
    condition     = length(aws_cloudfront_distribution.this) == 0
    error_message = "Expected no module-managed CloudFront distribution in external-integration mode."
  }

  assert {
    condition     = length(aws_lambda_permission.function_url_cloudfront_trusted) == 1
    error_message = "Expected one trusted external CloudFront permission in external-integration mode."
  }
}

run "allowing_any_cloudfront_distribution_supports_same_apply_integration" {
  command = plan

  variables {
    allow_all_cloudfront_distributions = true
    create_cloudfront_distribution     = false
  }

  override_data {
    target = data.aws_caller_identity.this[0]
    values = {
      account_id = "123456789012"
    }
  }

  override_data {
    target = data.aws_partition.this[0]
    values = {
      dns_suffix = "amazonaws.com"
      partition  = "aws"
    }
  }

  override_data {
    target = data.aws_region.this[0]
    values = {
      region = "eu-west-2"
    }
  }

  override_data {
    target = data.aws_iam_policy_document.assume_role[0]
    values = {
      json = <<JSON
      {
        "Version": "2012-10-17",
        "Statement": []
      }
      JSON
    }
  }

  override_data {
    target = data.aws_iam_policy_document.this[0]
    values = {
      json = <<JSON
      {
        "Version": "2012-10-17",
        "Statement": []
      }
      JSON
    }
  }

  override_data {
    target = data.aws_cloudfront_cache_policy.caching_disabled[0]
    values = {
      id = "managed-caching-disabled"
    }
  }

  override_data {
    target = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header[0]
    values = {
      id = "managed-all-viewer-except-host-header"
    }
  }

  assert {
    condition     = aws_lambda_function_url.this[0].authorization_type == "AWS_IAM"
    error_message = "Expected same-apply CloudFront integration mode to keep the function URL private."
  }

  assert {
    condition     = length(aws_lambda_permission.function_url_cloudfront_any) == 1
    error_message = "Expected the any-CloudFront permission in same-apply integration mode."
  }
}
