// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

locals {
  default_tags       = merge({ "terraform-module" = "unfunco/terraform-aws-contact-form" }, var.tags)
  function_name      = var.name
  lambda_output_path = format("%s/.contact-form-%s.zip", path.module, var.name)
  lambda_role_name   = format("%s-lambda", var.name)
  lambda_source_file = format("%s/lambda/handler.py", path.module)
  log_group_name     = format("/aws/lambda/%s", var.name)
}

resource "aws_cloudwatch_log_group" "this" {
  count = var.create ? 1 : 0

  kms_key_id = var.kms_key_arn
  name       = local.log_group_name
  tags       = local.default_tags
}

resource "aws_iam_role" "this" {
  count = var.create ? 1 : 0

  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
  description        = format("Execution role for the %s Lambda function.", local.function_name)
  name               = local.lambda_role_name
  path               = "/"
  tags               = local.default_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  count = var.create ? 1 : 0

  policy_arn = format("arn:%s:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", data.aws_partition.this[0].partition)
  role       = aws_iam_role.this[0].name
}

resource "aws_lambda_function" "this" {
  count = var.create ? 1 : 0

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy_attachment.lambda_basic_execution,
  ]

  architectures    = ["arm64"]
  description      = "Contact form handler."
  filename         = data.archive_file.lambda[0].output_path
  function_name    = local.function_name
  handler          = "handler.lambda_handler"
  memory_size      = var.memory_size
  package_type     = "Zip"
  role             = aws_iam_role.this[0].arn
  runtime          = "python3.14"
  source_code_hash = data.archive_file.lambda[0].output_base64sha256
  tags             = local.default_tags
  timeout          = 3
}

resource "aws_lambda_function_url" "this" {
  count = var.create ? 1 : 0

  authorization_type = "NONE"
  function_name      = aws_lambda_function.this[0].function_name

  cors {
    allow_headers = ["content-type"]
    allow_methods = ["POST"]
    allow_origins = ["*"]
  }
}

resource "aws_lambda_permission" "function_url" {
  count      = var.create ? 1 : 0
  depends_on = [aws_lambda_function_url.this]

  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.this[0].function_name
  function_url_auth_type = "NONE"
  principal              = "*"
  statement_id           = "AllowPublicFunctionUrl"
}

resource "aws_lambda_permission" "function_url_invoke" {
  count      = var.create ? 1 : 0
  depends_on = [aws_lambda_function_url.this]

  action                   = "lambda:InvokeFunction"
  function_name            = aws_lambda_function.this[0].function_name
  invoked_via_function_url = true
  principal                = "*"
  statement_id             = "AllowPublicFunctionUrlInvoke"
}
