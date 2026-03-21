// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

locals {
  default_tags = merge({ "terraform-module" = "unfunco/terraform-aws-contact-form" }, var.tags)

  enable_powertools = var.enable_logging || var.enable_tracing

  function_name = var.name

  lambda_architecture     = "arm64"
  lambda_environment_vars = merge(var.environment_variables, local.powertools_environment_vars)
  lambda_log_level        = upper(var.log_level)
  lambda_output_path      = format("%s/.contact-form-%s.zip", path.module, var.name)
  lambda_python_runtime   = "python3.14"
  lambda_role_name        = format("%s-lambda", var.name)
  lambda_source_file      = format("%s/lambda/handler.py", path.module)

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

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  count = var.create ? 1 : 0

  policy_arn = format("arn:%s:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole", data.aws_partition.this[0].partition)
  role       = aws_iam_role.this[0].name
}

resource "aws_iam_role_policy_attachment" "xray_daemon_write_access" {
  count = var.create && var.enable_tracing ? 1 : 0

  policy_arn = format("arn:%s:iam::aws:policy/AWSXRayDaemonWriteAccess", data.aws_partition.this[0].partition)
  role       = aws_iam_role.this[0].name
}

resource "aws_lambda_function" "this" {
  count = var.create ? 1 : 0

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.xray_daemon_write_access,
  ]

  architectures    = [local.lambda_architecture]
  description      = "Contact form handler."
  filename         = data.archive_file.lambda[0].output_path
  function_name    = local.function_name
  handler          = "handler.lambda_handler"
  memory_size      = var.memory_size
  package_type     = "Zip"
  role             = aws_iam_role.this[0].arn
  runtime          = local.lambda_python_runtime
  source_code_hash = data.archive_file.lambda[0].output_base64sha256
  tags             = local.default_tags
  timeout          = 3

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

resource "aws_lambda_function_url" "this" {
  count = var.create ? 1 : 0

  authorization_type = "NONE"
  function_name      = aws_lambda_function.this[0].function_name

  cors {
    allow_headers = ["content-type"]
    allow_methods = ["POST"]
    allow_origins = var.cors_allow_origins
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
