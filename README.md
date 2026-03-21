# Terraform module

[![CI](https://github.com/unfunco/template-terraform-module/actions/workflows/ci.yaml/badge.svg)](https://github.com/unfunco/template-terraform-module/actions/workflows/ci.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE.md)

A Terraform module for a minimal AWS Lambda contact form endpoint with a Lambda
Function URL.

## Getting started

### Requirements

- [Terraform] 1.14+

### Installation and usage

<!-- x-release-please-start-version -->

```terraform
module "contact_form" {
  source  = "unfunco/contact-form/aws"
  version = "0.0.0"
}

output "contact_form_url" {
  value = module.contact_form.lambda_url
}
```

<!-- x-release-please-end -->
<!-- BEGIN_TF_DOCS -->

### Resources

| Name                                                                                                                                                              | Type        |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)                                 | resource    |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                                         | resource    |
| [aws_iam_role_policy_attachment.lambda_basic_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)   | resource    |
| [aws_iam_role_policy_attachment.xray_daemon_write_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource    |
| [aws_lambda_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function)                                           | resource    |
| [aws_lambda_function_url.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_url)                                   | resource    |
| [aws_lambda_permission.function_url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission)                               | resource    |
| [aws_lambda_permission.function_url_invoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission)                        | resource    |
| [archive_file.lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file)                                                    | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)                         | data source |
| [aws_partition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition)                                                    | data source |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)                                                          | data source |

### Inputs

| Name                                  | Description                                                                                            | Type          | Default          | Required |
|---------------------------------------|--------------------------------------------------------------------------------------------------------|---------------|------------------|:--------:|
| create                                | Enable/disable the creation of all resources.                                                          | `bool`        | `true`           |    no    |
| enable\_logging                       | Enable JSON application logging configuration and Powertools logger support for the Lambda function.   | `bool`        | `true`           |    no    |
| enable\_powertools\_development\_mode | Enable Powertools development mode and debug logging for the Lambda function.                          | `bool`        | `false`          |    no    |
| enable\_tracing                       | Enable AWS X-Ray tracing and Powertools tracer support for the Lambda function.                        | `bool`        | `false`          |    no    |
| environment\_variables                | Additional environment variables to set on the Lambda function.                                        | `map(string)` | `{}`             |    no    |
| kms\_key\_arn                         | ARN of the KMS key to use for encrypting the log group.                                                | `string`      | `null`           |    no    |
| log\_level                            | Application log level for Lambda and Powertools. Valid values: TRACE, DEBUG, INFO, WARN, ERROR, FATAL. | `string`      | `"INFO"`         |    no    |
| log\_retention\_in\_days              | Number of days to retain logs in CloudWatch Log Group.                                                 | `number`      | `365`            |    no    |
| memory\_size                          | Amount of memory, in MB, allocated to the Lambda function.                                             | `number`      | `128`            |    no    |
| name                                  | Name to use for the Lambda function and related resources.                                             | `string`      | `"contact-form"` |    no    |
| tags                                  | Tags to be applied to all applicable resources.                                                        | `map(string)` | `{}`             |    no    |

### Outputs

| Name                   | Description                                                   |
|------------------------|---------------------------------------------------------------|
| lambda\_function\_arn  | ARN of the Lambda function.                                   |
| lambda\_function\_name | Name of the Lambda function.                                  |
| lambda\_role\_arn      | ARN of the Lambda execution role.                             |
| lambda\_url            | Public Lambda Function URL.                                   |
| log\_group\_name       | Name of the CloudWatch log group used by the Lambda function. |

<!-- END_TF_DOCS -->

### Releases

This repository uses [Release Please] to automate releases. When pull requests
with [conventional commit] messages are merged, Release Please will open or
update a pull request to bump the version and update the changelog. Once that
pull request is merged, a new release will be created.

## License

© 2026 [Daniel Morris]\
Made available under the terms of the [MIT License].

[conventional commit]: https://www.conventionalcommits.org
[daniel morris]: https://unfun.co
[mit license]: LICENSE.md
[release please]: https://github.com/googleapis/release-please
[terraform]: https://www.terraform.io
