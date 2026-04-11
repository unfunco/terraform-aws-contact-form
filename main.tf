// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

locals {
  cloudfront_origin_id = format("%s-origin", local.function_name)
  cloudfront_web_acl_arn = var.create ? (
    var.waf_web_acl_arn != null ? var.waf_web_acl_arn : try(aws_wafv2_web_acl.this[0].arn, null)
  ) : null
  create_managed_waf = var.create && var.create_waf && var.waf_web_acl_arn == null
  default_tags = merge({
    "terraform-module" = "unfunco/terraform-aws-contact-form"
  }, var.tags)

  email_notifications_enabled = length(var.email_recipients) > 0
  email_template              = coalesce(var.email_template, file("${path.module}/templates/email.html"))
  enable_powertools           = var.enable_logging || var.enable_tracing

  function_name = var.name
  kebab         = can(regex("^[a-z][a-z0-9]*(-[a-z0-9]+)*$", var.name))

  lambda_architecture    = "arm64"
  lambda_max_field_count = max(var.max_field_count, length(var.fields))

  lambda_environment_vars = merge(
    var.environment_variables,
    local.powertools_environment_vars,
    {
      CONTACT_FORM_FIELDS   = jsonencode(var.fields)
      EMAIL_TEMPLATE        = local.email_template
      MAX_FIELD_COUNT       = tostring(local.lambda_max_field_count)
      MAX_FIELD_LENGTH      = tostring(var.max_field_length)
      MAX_REQUEST_BODY_SIZE = tostring(var.max_request_body_size)
    },
    var.create && local.email_notifications_enabled ? {
      EMAIL_RECIPIENTS_SSM_PARAMETER_ARN = aws_ssm_parameter.email_recipients[0].arn
      SES_SOURCE_EMAIL                   = var.ses_source_email
    } : {}
  )

  lambda_log_level      = upper(var.log_level)
  lambda_output_path    = format("%s/.contact-form-%s.zip", path.module, var.name)
  lambda_python_runtime = "python3.14"
  lambda_role_name      = local.kebab ? format("%s-lambda", var.name) : format("%sLambda", var.name)
  lambda_source_file    = format("%s/lambda/handler.py", path.module)
  lambda_url_domain_name = try(
    trimsuffix(trimprefix(aws_lambda_function_url.this[0].function_url, "https://"), "/"),
    null,
  )

  log_group_name = format("/aws/lambda/%s", var.name)

  powertools_environment_vars = local.enable_powertools ? merge(
    {
      ENABLE_LOGGING            = tostring(var.enable_logging)
      ENABLE_TRACING            = tostring(var.enable_tracing)
      POWERTOOLS_LOG_LEVEL      = local.lambda_log_level
      POWERTOOLS_SERVICE_NAME   = local.function_name
      POWERTOOLS_TRACE_DISABLED = tostring(!var.enable_tracing)
    },
    local.powertools_log_event ? {
      POWERTOOLS_LOGGER_LOG_EVENT = "true"
    } : {},
    var.enable_powertools_development_mode ? {
      POWERTOOLS_DEBUG = "true"
      POWERTOOLS_DEV   = "true"
    } : {},
  ) : {}

  powertools_layer_runtime = replace(local.lambda_python_runtime, ".", "")
  powertools_log_event     = var.enable_logging && (var.enable_powertools_development_mode || local.lambda_log_level == "DEBUG")
  ses_source_domain        = try(split("@", var.ses_source_email)[1], null)
  ses_identity_names = local.email_notifications_enabled ? distinct(flatten([
    var.ses_source_email != null ? [var.ses_source_email] : [],
    local.ses_source_domain != null ? [local.ses_source_domain] : [],
  ])) : []
  ses_identity_arns = var.create && local.email_notifications_enabled ? [
    for identity in local.ses_identity_names : format(
      "arn:%s:ses:%s:%s:identity/%s",
      data.aws_partition.this[0].partition,
      data.aws_region.this[0].region,
      data.aws_caller_identity.this[0].account_id,
      identity,
    )
  ] : []

  use_cloudfront_origin_protection = (
    var.create_cloudfront_distribution ||
    var.allow_all_cloudfront_distributions ||
    length(var.trusted_cloudfront_distribution_arns) > 0
  )
  function_url_auth_type = local.use_cloudfront_origin_protection ? "AWS_IAM" : "NONE"
}

resource "aws_cloudwatch_log_group" "this" {
  count = var.create ? 1 : 0

  deletion_protection_enabled = true
  kms_key_id                  = var.kms_key_arn
  log_group_class             = "STANDARD"
  name                        = local.log_group_name
  retention_in_days           = var.log_retention_in_days
  skip_destroy                = true
  tags                        = local.default_tags
}

resource "aws_iam_role" "this" {
  count = var.create ? 1 : 0

  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
  description        = format("Execution role for the %s Lambda function.", local.function_name)
  name               = local.lambda_role_name
  path               = "/"
  tags               = local.default_tags
}

resource "aws_iam_role_policy" "this" {
  count = var.create ? 1 : 0

  name   = local.kebab ? format("%s-execution", local.function_name) : format("%sExecution", local.function_name)
  policy = data.aws_iam_policy_document.this[0].json
  role   = aws_iam_role.this[0].name
}

resource "aws_ssm_parameter" "email_recipients" {
  count = var.create && local.email_notifications_enabled ? 1 : 0

  description = "List of email recipients for contact form notifications."
  key_id      = var.kms_key_arn
  name        = format("/contact-form/%s/email-recipients", var.name)
  tags        = local.default_tags
  type        = "SecureString"
  value       = join(",", var.email_recipients)
}

resource "aws_lambda_function" "this" {
  count = var.create ? 1 : 0

  architectures                  = [local.lambda_architecture]
  description                    = "Contact form handler."
  filename                       = data.archive_file.lambda[0].output_path
  function_name                  = local.function_name
  handler                        = "handler.lambda_handler"
  kms_key_arn                    = var.kms_key_arn
  memory_size                    = var.memory_size
  package_type                   = "Zip"
  reserved_concurrent_executions = var.reserved_concurrent_executions
  role                           = aws_iam_role.this[0].arn
  runtime                        = local.lambda_python_runtime
  source_code_hash               = data.archive_file.lambda[0].output_base64sha256
  tags                           = local.default_tags
  timeout                        = 3

  dynamic "environment" {
    for_each = length(local.lambda_environment_vars) > 0 ? [1] : []

    content {
      variables = local.lambda_environment_vars
    }
  }

  layers = local.enable_powertools ? [
    format(
      "arn:%s:lambda:%s:017000801446:layer:AWSLambdaPowertoolsPythonV3-%s-%s:27",
      data.aws_partition.this[0].partition,
      data.aws_region.this[0].region,
      local.powertools_layer_runtime,
      local.lambda_architecture,
    ),
  ] : null

  dynamic "logging_config" {
    for_each = var.enable_logging ? [1] : []

    content {
      application_log_level = local.lambda_log_level
      log_format            = "JSON"
      log_group             = aws_cloudwatch_log_group.this[0].name
      system_log_level      = "WARN"
    }
  }

  tracing_config {
    mode = var.enable_tracing ? "Active" : "PassThrough"
  }
}

resource "aws_cloudfront_origin_access_control" "this" {
  count = var.create && local.use_cloudfront_origin_protection ? 1 : 0

  description                       = format("Origin access control for the %s contact form Lambda Function URL.", local.function_name)
  name                              = local.kebab ? format("%s-origin-access-control", var.name) : format("%sOriginAccessControl", var.name)
  origin_access_control_origin_type = "lambda"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_lambda_function_url" "this" {
  count = var.create ? 1 : 0

  authorization_type = local.function_url_auth_type
  function_name      = aws_lambda_function.this[0].function_name

  cors {
    allow_headers = ["content-type"]
    allow_methods = ["POST"]
    allow_origins = var.cors_allow_origins
  }
}

resource "aws_wafv2_web_acl" "this" {
  count  = local.create_managed_waf ? 1 : 0
  region = "us-east-1"

  name        = local.kebab ? format("%s-web-acl", var.name) : format("%sWebAcl", var.name)
  description = format("Protects the public CloudFront distribution for the %s contact form endpoint.", local.function_name)
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "BlockUnexpectedMethods"
    priority = 0

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          or_statement {
            statement {
              byte_match_statement {
                positional_constraint = "EXACTLY"
                search_string         = "OPTIONS"

                field_to_match {
                  method {}
                }

                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }

            statement {
              byte_match_statement {
                positional_constraint = "EXACTLY"
                search_string         = "POST"

                field_to_match {
                  method {}
                }

                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockUnexpectedMethods"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 20

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 30

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "RateLimitPerIP"
    priority = 40

    action {
      block {}
    }

    statement {
      rate_based_statement {
        aggregate_key_type = "IP"
        limit              = var.waf_rate_limit
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitPerIP"
      sampled_requests_enabled   = true
    }
  }

  dynamic "rule" {
    for_each = var.enable_waf_bot_control ? [1] : []

    content {
      name     = "AWSManagedRulesBotControlRuleSet"
      priority = 50

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = "AWSManagedRulesBotControlRuleSet"
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "BotControlRuleSet"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = replace(format("%sWebAcl", local.function_name), "-", "")
    sampled_requests_enabled   = true
  }

  tags = local.default_tags
}

resource "aws_cloudfront_distribution" "this" {
  count = var.create && var.create_cloudfront_distribution ? 1 : 0

  comment             = format("Contact form endpoint for %s.", local.function_name)
  enabled             = true
  http_version        = "http2and3"
  is_ipv6_enabled     = true
  price_class         = var.cloudfront_price_class
  tags                = local.default_tags
  wait_for_deployment = true
  web_acl_id          = local.cloudfront_web_acl_arn

  default_cache_behavior {
    allowed_methods          = ["OPTIONS", "POST"]
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled[0].id
    cached_methods           = ["OPTIONS"]
    compress                 = true
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host_header[0].id
    target_origin_id         = local.cloudfront_origin_id
    viewer_protocol_policy   = "redirect-to-https"
  }

  origin {
    domain_name              = trimsuffix(trimprefix(aws_lambda_function_url.this[0].function_url, "https://"), "/")
    origin_access_control_id = aws_cloudfront_origin_access_control.this[0].id
    origin_id                = local.cloudfront_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_read_timeout    = 30
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

resource "aws_lambda_permission" "function_url_public" {
  count = var.create && !local.use_cloudfront_origin_protection ? 1 : 0

  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.this[0].function_name
  function_url_auth_type = "NONE"
  principal              = "*"
  statement_id           = "AllowPublicFunctionUrl"
}

resource "aws_lambda_permission" "function_url_public_invoke" {
  count = var.create && !local.use_cloudfront_origin_protection ? 1 : 0

  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.this[0].function_name
  invoked_via_function_url = true
  principal                = "*"
  statement_id             = "AllowPublicFunctionUrlInvoke"
}

resource "aws_lambda_permission" "function_url_cloudfront_managed" {
  count = var.create && var.create_cloudfront_distribution ? 1 : 0

  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.this[0].function_name
  function_url_auth_type = "AWS_IAM"
  principal              = "cloudfront.amazonaws.com"
  source_arn             = aws_cloudfront_distribution.this[0].arn
  statement_id           = "AllowManagedCloudFrontFunctionUrl"
}

resource "aws_lambda_permission" "function_url_cloudfront_managed_invoke" {
  count = var.create && var.create_cloudfront_distribution ? 1 : 0

  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.this[0].function_name
  invoked_via_function_url = true
  principal                = "cloudfront.amazonaws.com"
  source_arn               = aws_cloudfront_distribution.this[0].arn
  statement_id             = "AllowManagedCloudFrontFunctionUrlInvoke"
}

resource "aws_lambda_permission" "function_url_cloudfront_any" {
  count = var.create && !var.create_cloudfront_distribution && var.allow_all_cloudfront_distributions ? 1 : 0

  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.this[0].function_name
  function_url_auth_type = "AWS_IAM"
  principal              = "cloudfront.amazonaws.com"
  statement_id           = "AllowAnyCloudFrontFunctionUrl"
}

resource "aws_lambda_permission" "function_url_cloudfront_any_invoke" {
  count = var.create && !var.create_cloudfront_distribution && var.allow_all_cloudfront_distributions ? 1 : 0

  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.this[0].function_name
  invoked_via_function_url = true
  principal                = "cloudfront.amazonaws.com"
  statement_id             = "AllowAnyCloudFrontFunctionUrlInvoke"
}

resource "aws_lambda_permission" "function_url_cloudfront_trusted" {
  for_each = var.create ? { for arn in var.trusted_cloudfront_distribution_arns : arn => arn } : {}

  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.this[0].function_name
  function_url_auth_type = "AWS_IAM"
  principal              = "cloudfront.amazonaws.com"
  source_arn             = each.value
  statement_id           = format("AllowCloudFrontUrl%s", substr(md5(each.value), 0, 12))
}

resource "aws_lambda_permission" "function_url_cloudfront_trusted_invoke" {
  for_each = var.create ? { for arn in var.trusted_cloudfront_distribution_arns : arn => arn } : {}

  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.this[0].function_name
  invoked_via_function_url = true
  principal                = "cloudfront.amazonaws.com"
  source_arn               = each.value
  statement_id             = format("AllowCloudFrontInvoke%s", substr(md5(each.value), 0, 12))
}
