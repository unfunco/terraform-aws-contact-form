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

  email_recipients = ["hello@example.com"]
  ses_source_email = "no-reply@example.com"
}

output "contact_form_url" {
  value = module.contact_form.lambda_url
}
```

```html

<form action="https://<>" method="post">
  <input name="email" type="email" required />
  <input name="name" type="text" required />
  <textarea name="message" required></textarea>
  <button type="submit">Send</button>
</form>
```

The endpoint currently expects exactly three fields: `name`, `email`, and
`message`. Standard HTML form submissions
(`application/x-www-form-urlencoded`) and JSON requests are supported.

```sh
curl -X POST https://<> \
  -H 'content-type: application/json' \
  -d '{"name":"Alice Example","email":"alice@example.com","message":"Hello"}'
```

Successful submissions return `200 OK` with a JSON confirmation message.
Validation failures return a JSON `4xx` response describing the problem.

<!-- x-release-please-end -->
<!-- BEGIN_TF_DOCS -->

### Resources

| Name                                                                                                                                       | Type        |
|--------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)          | resource    |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                  | resource    |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy)                    | resource    |
| [aws_lambda_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function)                    | resource    |
| [aws_lambda_function_url.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_url)            | resource    |
| [aws_lambda_permission.function_url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission)        | resource    |
| [aws_lambda_permission.function_url_invoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource    |
| [aws_ssm_parameter.email_recipients](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter)            | resource    |
| [archive_file.lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file)                             | data source |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity)                 | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)  | data source |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document)         | data source |
| [aws_partition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition)                             | data source |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region)                                   | data source |

### Inputs

| Name                                  | Description                                                                                                                                         | Type           | Default          | Required |
|---------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|----------------|------------------|:--------:|
| cors\_allow\_origins                  | List of allowed origins for CORS.                                                                                                                   | `list(string)` | ```[ "*" ]```    |    no    |
| create                                | Enable/disable the creation of all resources.                                                                                                       | `bool`         | `true`           |    no    |
| email\_recipients                     | List of emails to receive notifications. Requires ses\_source\_email when not empty.                                                                | `list(string)` | `[]`             |    no    |
| enable\_logging                       | Enable JSON application logging configuration and Powertools logger support for the Lambda function.                                                | `bool`         | `true`           |    no    |
| enable\_powertools\_development\_mode | Enable Powertools development mode, debug logging, and Powertools event logging for the Lambda function.                                            | `bool`         | `false`          |    no    |
| enable\_tracing                       | Enable AWS X-Ray tracing and Powertools tracer support for the Lambda function.                                                                     | `bool`         | `false`          |    no    |
| environment\_variables                | Additional environment variables to set on the Lambda function.                                                                                     | `map(string)`  | `{}`             |    no    |
| kms\_key\_arn                         | ARN of the KMS key to use for encrypting the log group.                                                                                             | `string`       | `null`           |    no    |
| log\_level                            | Application log level for Lambda and Powertools. Valid values: TRACE, DEBUG, INFO, WARN, ERROR, FATAL. DEBUG also enables Powertools event logging. | `string`       | `"INFO"`         |    no    |
| log\_retention\_in\_days              | Number of days to retain logs in CloudWatch Log Group.                                                                                              | `number`       | `365`            |    no    |
| memory\_size                          | Amount of memory, in MB, allocated to the Lambda function.                                                                                          | `number`       | `128`            |    no    |
| name                                  | Name to use for the Lambda function and related resources.                                                                                          | `string`       | `"contact-form"` |    no    |
| ses\_source\_email                    | Verified SES sender address used for notifications. Required when email\_recipients is not empty.                                                   | `string`       | `null`           |    no    |
| tags                                  | Tags to be applied to all applicable resources.                                                                                                     | `map(string)`  | `{}`             |    no    |

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
