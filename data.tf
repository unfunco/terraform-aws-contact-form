// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

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

    principals {
      identifiers = [format("lambda.%s", data.aws_partition.this[0].dns_suffix)]
      type        = "Service"
    }
  }
}

data "archive_file" "lambda" {
  count = var.create ? 1 : 0

  output_path = local.lambda_output_path
  source_file = local.lambda_source_file
  type        = "zip"
}
