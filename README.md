# Terraform module

[![CI](https://github.com/unfunco/template-terraform-module/actions/workflows/ci.yaml/badge.svg)](https://github.com/unfunco/template-terraform-module/actions/workflows/ci.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE.md)

A template for creating a Terraform module repository.

## Getting started

### Requirements

- [Terraform] 1.14+

### Installation and usage

<!-- x-release-please-start-version -->

```terraform
module "example" {
  source  = "unfunco/module-name/aws"
  version = "0.0.0"

  // ...
}
```

<!-- x-release-please-end -->
<!-- BEGIN_TF_DOCS -->

### Inputs

| Name   | Description                                     | Type          | Default | Required |
|--------|-------------------------------------------------|---------------|---------|:--------:|
| create | Enable/disable the creation of all resources.   | `bool`        | `true`  |    no    |
| tags   | Tags to be applied to all applicable resources. | `map(string)` | `{}`    |    no    |

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
