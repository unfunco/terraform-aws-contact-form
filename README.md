# Terraform module

[![CI](https://github.com/unfunco/template-terraform-module/actions/workflows/ci.yaml/badge.svg)](https://github.com/unfunco/template-terraform-module/actions/workflows/ci.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE.md)

A Terraform module for an AWS Lambda contact form endpoint fronted by CloudFront
and protected by AWS WAF.

## Getting started

### Requirements

- [Terraform] 1.14+

### Installation and usage

<!-- x-release-please-start-version -->

```terraform
provider "aws" {
  region = "eu-west-2"
}

module "contact_form" {
  source  = "unfunco/contact-form/aws"
  version = "0.1.0"

  email_recipients = ["hello@example.com"]
  ses_source_email = "no-reply@example.com"
}

output "contact_form_url" {
  value = module.contact_form.endpoint_url
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

```terraform
module "contact_form" {
  source  = "unfunco/contact-form/aws"
  version = "0.1.0"

  name                           = "unfunco-contact-form"
  create_cloudfront_distribution = false
  allow_all_cloudfront_distributions = true

  cors_allow_origins = [
    "https://unfun.co",
    "https://www.unfun.co",
  ]

  email_recipients = ["hello@unfun.co"]
  ses_source_email = "no-reply@unfun.co"
}
```

<!-- x-release-please-end -->

```terraform
module "unfunco_website" {
  source  = "unfunco/static-website/aws"
  version = "0.5.0"

  domain_name         = "unfun.co"
  cloudfront_web_acl_id = module.contact_form.waf_web_acl_arn

  cloudfront_additional_origins = {
    contact_form = {
      domain_name              = module.contact_form.cloudfront_origin_domain_name
      origin_access_control_id = module.contact_form.cloudfront_origin_access_control_id
    }
  }

  cloudfront_ordered_cache_behaviors = [
    {
      path_pattern             = "/contact"
      allowed_methods          = ["OPTIONS", "POST"]
      cached_methods           = ["OPTIONS"]
      cache_policy_id          = module.contact_form.cloudfront_cache_policy_id
      origin_request_policy_id = module.contact_form.cloudfront_origin_request_policy_id
      target_origin_id         = "contact_form"
    },
  ]
}
```

```sh
curl -X POST https://<> \
  -H 'content-type: application/json' \
  -d '{"name":"Alice Example","email":"alice@example.com","message":"Hello"}'
```

Successful submissions return `200 OK` with a JSON confirmation message.
Validation failures return a JSON `4xx` response describing the problem.

<!-- BEGIN_TF_DOCS -->

### Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudfront_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_origin_access_control.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_access_control) | resource |
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_lambda_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function_url.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_url) | resource |
| [aws_lambda_permission.function_url_cloudfront_any](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.function_url_cloudfront_any_invoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.function_url_cloudfront_managed](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.function_url_cloudfront_managed_invoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.function_url_cloudfront_trusted](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.function_url_cloudfront_trusted_invoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.function_url_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.function_url_public_invoke](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_ssm_parameter.email_recipients](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_wafv2_web_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [archive_file.lambda](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_cloudfront_cache_policy.caching_disabled](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_origin_request_policy.all_viewer_except_host_header](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_origin_request_policy) | data source |
| [aws_iam_policy_document.assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

### Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| allow\_all\_cloudfront\_distributions | Allow any CloudFront distribution to invoke the Lambda Function URL with SigV4-signed requests. This is useful when integrating with another CloudFront distribution in the same Terraform apply and its ARN is not available yet. Prefer trusted\_cloudfront\_distribution\_arns when possible. | `bool` | `false` | no |
| cloudfront\_price\_class | Price class for the CloudFront distribution that fronts the contact form endpoint. | `string` | `"PriceClass_100"` | no |
| cors\_allow\_origins | List of allowed origins for CORS. | `list(string)` | ```[ "*" ]``` | no |
| create | Enable/disable the creation of all resources. | `bool` | `true` | no |
| create\_cloudfront\_distribution | Create a CloudFront distribution in front of the Lambda Function URL so the public endpoint can be protected by AWS WAF and the raw function URL can remain private to CloudFront. | `bool` | `true` | no |
| create\_waf | Create a secure-by-default AWS WAF web ACL for the public CloudFront distribution. The CloudFront-scope web ACL is managed in us-east-1 internally, as required by AWS. | `bool` | `true` | no |
| email\_recipients | List of emails to receive notifications. Requires ses\_source\_email when not empty. | `list(string)` | `[]` | no |
| email\_template | Custom HTML email template content. Use $field\_name or $fields\_html for variable substitution with form values. When null, the default template is used. | `string` | `null` | no |
| enable\_logging | Enable JSON application logging configuration and Powertools logger support for the Lambda function. | `bool` | `true` | no |
| enable\_powertools\_development\_mode | Enable Powertools development mode, debug logging, and Powertools event logging for the Lambda function. | `bool` | `false` | no |
| enable\_tracing | Enable AWS X-Ray tracing and Powertools tracer support for the Lambda function. | `bool` | `false` | no |
| enable\_waf\_bot\_control | Enable the AWS Managed Bot Control rule group on the module-managed WAF. This improves abuse resistance but incurs additional AWS WAF charges. | `bool` | `false` | no |
| environment\_variables | Additional environment variables to set on the Lambda function. | `map(string)` | `{}` | no |
| fields | List of form fields to accept and validate. Supported types: text, email, textarea. | ```list(object({ name = string type = string }))``` | ```[ { "name": "name", "type": "text" }, { "name": "email", "type": "email" }, { "name": "message", "type": "textarea" } ]``` | no |
| kms\_key\_arn | ARN of the KMS key to use for encrypting the log group. | `string` | `null` | no |
| log\_level | Application log level for Lambda and Powertools. Valid values: TRACE, DEBUG, INFO, WARN, ERROR, FATAL. DEBUG also enables Powertools event logging. | `string` | `"INFO"` | no |
| log\_retention\_in\_days | Number of days to retain logs in CloudWatch Log Group. | `number` | `365` | no |
| memory\_size | Amount of memory, in MB, allocated to the Lambda function. | `number` | `128` | no |
| name | Name to use for the Lambda function and related resources. | `string` | `"contact-form"` | no |
| ses\_source\_email | Verified SES sender address used for notifications. Required when email\_recipients is not empty. | `string` | `null` | no |
| tags | Tags to be applied to all applicable resources. | `map(string)` | `{}` | no |
| trusted\_cloudfront\_distribution\_arns | Existing CloudFront distribution ARNs that should be allowed to invoke the Lambda Function URL when you are routing contact-form traffic through another distribution, such as unfunco/static-website/aws. | `list(string)` | `[]` | no |
| waf\_rate\_limit | Maximum number of requests allowed from a single IP address in a rolling 5-minute window before the module-managed AWS WAF blocks it. | `number` | `100` | no |
| waf\_web\_acl\_arn | Existing CLOUDFRONT-scope AWS WAF web ACL ARN to associate with the CloudFront distribution instead of creating one. | `string` | `null` | no |

### Outputs

| Name | Description |
| ---- | ----------- |
| cloudfront\_cache\_policy\_id | CloudFront cache policy ID that disables caching for the contact form endpoint. |
| cloudfront\_distribution\_arn | ARN of the CloudFront distribution that fronts the contact form endpoint. |
| cloudfront\_domain\_name | CloudFront domain name for the public contact form endpoint. |
| cloudfront\_origin\_access\_control\_id | CloudFront origin access control ID for securely using the Lambda Function URL as an origin in another CloudFront distribution, such as unfunco/static-website/aws. |
| cloudfront\_origin\_domain\_name | Domain name to use when wiring the Lambda Function URL into another CloudFront distribution as a custom origin. |
| cloudfront\_origin\_request\_policy\_id | CloudFront origin request policy ID that forwards viewer headers except Host, suitable for Lambda Function URL origins. |
| endpoint\_url | Public URL to use for contact form submissions when this module manages the public endpoint itself. This is the CloudFront URL when the distribution is enabled; otherwise it falls back to the raw Lambda Function URL only when that URL is public. |
| lambda\_function\_arn | ARN of the Lambda function. |
| lambda\_function\_name | Name of the Lambda function. |
| lambda\_role\_arn | ARN of the Lambda execution role. |
| lambda\_url | Lambda Function URL used as the CloudFront origin. When this module manages CloudFront or trusted\_cloudfront\_distribution\_arns is set, this URL requires IAM-signed requests and is not intended for browsers. |
| log\_group\_name | Name of the CloudWatch log group used by the Lambda function. |
| waf\_web\_acl\_arn | ARN of the AWS WAF web ACL created or used for the public CloudFront endpoint, whether that distribution is managed here or by another module. |
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
