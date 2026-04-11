// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

data "aws_caller_identity" "this" {
  count = var.create ? 1 : 0
}

data "aws_partition" "this" {
  count = var.create ? 1 : 0
}

data "aws_region" "this" {
  count = var.create ? 1 : 0
}

data "aws_iam_policy_document" "assume_role" {
  count = var.create ? 1 : 0

  version = "2012-10-17"

  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    sid     = "AllowLambdaServiceToAssumeContactFormRole"

    principals {
      identifiers = [format("lambda.%s", data.aws_partition.this[0].dns_suffix)]
      type        = "Service"
    }
  }
}

data "aws_iam_policy_document" "this" {
  count = var.create ? 1 : 0

  version = "2012-10-17"

  dynamic "statement" {
    for_each = var.kms_key_arn != null ? [1] : []

    content {
      actions   = ["kms:Decrypt"]
      effect    = "Allow"
      resources = [var.kms_key_arn]
      sid       = "AllowContactFormParameterDecryption"
    }
  }

  dynamic "statement" {
    for_each = var.enable_logging ? [1] : []

    content {
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
      ]
      effect = "Allow"
      resources = [
        format(
          "arn:%s:logs:%s:%s:log-group:/aws/lambda/%s:*",
          data.aws_partition.this[0].partition,
          data.aws_region.this[0].region,
          data.aws_caller_identity.this[0].account_id,
          local.function_name,
        ),
      ]
      sid = "AllowContactFormLogging"
    }
  }

  dynamic "statement" {
    for_each = local.email_notifications_enabled ? [1] : []

    content {
      actions   = ["ses:SendEmail"]
      effect    = "Allow"
      resources = local.ses_identity_arns
      sid       = "AllowContactFormEmailNotifications"

      condition {
        test     = "StringEquals"
        values   = [var.ses_source_email]
        variable = "ses:FromAddress"
      }

      condition {
        test     = "ForAllValues:StringEquals"
        values   = var.email_recipients
        variable = "ses:Recipients"
      }
    }
  }

  dynamic "statement" {
    for_each = local.email_notifications_enabled ? [1] : []

    content {
      actions = ["ssm:GetParameter"]
      effect  = "Allow"
      resources = [
        format(
          "arn:%s:ssm:%s:%s:parameter/contact-form/%s/email-recipients",
          data.aws_partition.this[0].partition,
          data.aws_region.this[0].region,
          data.aws_caller_identity.this[0].account_id,
          var.name,
        ),
      ]
      sid = "AllowContactFormEmailRecipientsParameterAccess"
    }
  }

  dynamic "statement" {
    for_each = var.enable_tracing ? [1] : []

    content {
      actions = [
        "xray:GetSamplingRules",
        "xray:GetSamplingStatisticSummaries",
        "xray:GetSamplingTargets",
        "xray:PutTelemetryRecords",
        "xray:PutTraceSegments",
      ]
      effect    = "Allow"
      resources = ["*"]
      sid       = "AllowContactFormXRayDaemonWriteAccess"
    }
  }
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  count = var.create ? 1 : 0

  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host_header" {
  count = var.create ? 1 : 0

  name = "Managed-AllViewerExceptHostHeader"
}

data "archive_file" "lambda" {
  count = var.create ? 1 : 0

  output_path = local.lambda_output_path
  source_file = local.lambda_source_file
  type        = "zip"
}
