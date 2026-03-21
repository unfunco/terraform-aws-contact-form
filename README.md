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

### Inputs

| Name        | Description                                                | Type          | Default          | Required |
|-------------|------------------------------------------------------------|---------------|------------------|:--------:|
| create      | Enable/disable the creation of all resources.              | `bool`        | `true`           |    no    |
| kms_key_arn | ARN of the KMS key to use for encrypting the log group.    | `string`      | `null`           |    no    |
| memory_size | Amount of memory, in MB, allocated to the Lambda function. | `number`      | `128`            |    no    |
| name        | Name to use for the Lambda function and related resources. | `string`      | `"contact-form"` |    no    |
| tags        | Tags to be applied to all applicable resources.            | `map(string)` | `{}`             |    no    |

### Outputs

| Name                 | Description                                                   |
|----------------------|---------------------------------------------------------------|
| lambda_function_arn  | ARN of the Lambda function.                                   |
| lambda_function_name | Name of the Lambda function.                                  |
| lambda_role_arn      | ARN of the Lambda execution role.                             |
| lambda_url           | Public Lambda Function URL.                                   |
| log_group_name       | Name of the CloudWatch log group used by the Lambda function. |

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
