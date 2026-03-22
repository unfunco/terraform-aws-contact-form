// SPDX-FileCopyrightText: 2026 Daniel Morris <daniel@honestempire.com>
// SPDX-License-Identifier: MIT

mock_provider "archive" {}
mock_provider "aws" {}

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

  assert {
    condition     = aws_iam_role.this[0].name == "contact-form-lambda"
    error_message = "Expected role name 'contact-form-lambda', got '${aws_iam_role.this[0].name}'."
  }

  assert {
    condition     = aws_iam_role_policy.this[0].name == "contact-form-execution"
    error_message = "Expected policy name 'contact-form-execution', got '${aws_iam_role_policy.this[0].name}'."
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

  assert {
    condition     = aws_iam_role.this[0].name == "ContactFormLambda"
    error_message = "Expected role name 'ContactFormLambda', got '${aws_iam_role.this[0].name}'."
  }

  assert {
    condition     = aws_iam_role_policy.this[0].name == "ContactFormExecution"
    error_message = "Expected policy name 'ContactFormExecution', got '${aws_iam_role_policy.this[0].name}'."
  }
}
