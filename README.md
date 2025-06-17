# AWS Github OIDC Provider Terraform Module

This module allows you to create a GitHub OIDC provider (supporting both GitHub Actions and GitHub Audit Log streams) and associated IAM roles. This enables GitHub Actions, or external systems consuming GitHub audit logs via OIDC, to securely authenticate against the AWS API using an IAM role.

We recommend using GitHub's OIDC provider to get short-lived credentials needed for your actions. Specifying role-to-assume without providing an aws-access-key-id or a web-identity-token-file will signal to the action that you wish to use the OIDC provider. The default session duration is 1 hour when using the OIDC provider to directly assume an IAM Role. The default session duration is 6 hours when using an IAM User to assume an IAM Role (by providing an aws-access-key-id, aws-secret-access-key, and a role-to-assume) . If you would like to adjust this you can pass a duration to role-duration-seconds, but the duration cannot exceed the maximum that was defined when the IAM Role was created. The default session name is GitHubActions, and you can modify it by specifying the desired name in role-session-name.

- [How to Hook EKS](docs/hot-to-eks.md)

## Features

1. Create an AWS OIDC provider for GitHub Actions
1. Create one or more IAM role that can be assumed by GitHub Actions
1. IAM roles can be scoped to :
     * One or more GitHub organisations
     * One or more GitHub repository
     * One or more branches in a repository


| Feature                                                                                                | Status |
|--------------------------------------------------------------------------------------------------------|--------|
| Support for GitHub Actions and Audit Log OIDC providers                                                | ✅     |
| Create a role for all repositories in a specific Github organisation                                    | ✅     |
| Create a role specific to a repository for a specific organisation                                       | ✅     |
| Create a role specific to a branch in a repository                                                      | ✅     |
| Create a role for multiple organisations/repositories/branches                                         | ✅     |
| Create a role for organisations/repositories/branches selected by wildcard (e.g. `feature/*` branches) | ✅     |

---

[![linter](https://github.com/terraform-module/terraform-aws-github-oidc-provider/actions/workflows/linter.yml/badge.svg)](https://github.com/terraform-module/terraform-aws-github-oidc-provider/actions/workflows/linter.yml)
[![release.draft](https://github.com/terraform-module/terraform-aws-github-oidc-provider/actions/workflows/release.draft.yml/badge.svg)](https://github.com/terraform-module/terraform-aws-github-oidc-provider/actions/workflows/release.draft.yml)

[![](https://img.shields.io/github/license/terraform-module/terraform-aws-github-oidc-provider)](https://github.com/terraform-module/terraform-aws-github-oidc-provider)
![](https://img.shields.io/github/v/tag/terraform-module/terraform-aws-github-oidc-provider)
![](https://img.shields.io/issues/github/terraform-module/terraform-aws-github-oidc-provider)
![](https://img.shields.io/github/issues/terraform-module/terraform-aws-github-oidc-provider)
![](https://img.shields.io/github/issues-closed/terraform-module/terraform-aws-github-oidc-provider)
[![](https://img.shields.io/github/languages/code-size/terraform-module/terraform-aws-github-oidc-provider)](https://github.com/terraform-module/terraform-aws-github-oidc-provider)
[![](https://img.shields.io/github/repo-size/terraform-module/terraform-aws-github-oidc-provider)](https://github.com/terraform-module/terraform-aws-github-oidc-provider)
![](https://img.shields.io/github/languages/top/terraform-module/terraform-aws-github-oidc-provider?color=green&logo=terraform&logoColor=blue)
![](https://img.shields.io/github/commit-activity/m/terraform-module/terraform-aws-github-oidc-provider)
![](https://img.shields.io/github/contributors/terraform-module/terraform-aws-github-oidc-provider)
![](https://img.shields.io/github/last-commit/terraform-module/terraform-aws-github-oidc-provider)
[![Maintenance](https://img.shields.io/badge/Maintenu%3F-oui-green.svg)](https://GitHub.com/terraform-module/terraform-aws-github-oidc-provider/graphs/commit-activity)
[![GitHub forks](https://img.shields.io/github/forks/terraform-module/terraform-aws-github-oidc-provider.svg?style=social&label=Fork)](https://github.com/terraform-module/terraform-aws-github-oidc-provider)

---

## Documentation

- [TFLint Rules](https://github.com/terraform-linters/tflint/tree/master/docs/rules)

## Provider Types and Conditions

This module supports two types of GitHub OIDC providers, configurable via the `github_provider` input variable:

*   `"actions"` (default): For integrating with GitHub Actions.
    *   The OIDC provider URL will be `https://token.actions.githubusercontent.com`.
    *   The thumbprint used will be taken from the `var.github_thumbprint` input variable, which defaults to the standard thumbprint for GitHub Actions.
    *   The IAM role's trust policy will include:
        *   A condition checking `token.actions.githubusercontent.com:aud` equals `sts.amazonaws.com`.
        *   If `var.repositories` is provided (recommended for scoping permissions), an additional condition restricts `token.actions.githubusercontent.com:sub` (subject) using `StringLike` to patterns like `repo:your-org/your-repo:*`.

*   `"audit-log"`: For integrating with GitHub Enterprise Audit Log streaming using OIDC.
    *   The OIDC provider URL will be `https://oidc-configuration.audit-log.githubusercontent.com`.
    *   The thumbprint used is specific to the audit log OIDC endpoint and is managed internally by the module.
    *   The `var.enterprise_name` input variable **must** be set to your GitHub Enterprise name (case-sensitive).
    *   The IAM role's trust policy will include:
        *   A condition checking `oidc-configuration.audit-log.githubusercontent.com:aud` equals `sts.amazonaws.com`.
        *   If `var.enterprise_name` is provided, an additional condition restricts `oidc-configuration.audit-log.githubusercontent.com:sub` (subject) using `StringEquals` to `https://github.com/YOUR_ENTERPRISE_NAME` (where `YOUR_ENTERPRISE_NAME` is from `var.enterprise_name`).

### Default Usage (GitHub Actions)

IMPORTANT: The master branch is used in `source` just as an example in older READMEs. In your code, do not pin to master because there may be breaking changes between releases. Instead pin to the release tag (e.g. `?ref=tags/x.y.z` or `version = "x.y.z"`) of one of our [latest releases](https://github.com/terraform-module/terraform-aws-github-oidc-provider/releases).

```hcl
module "github_oidc_actions" {
  source  = "terraform-module/github-oidc-provider/aws"
  version = "~> 1.0" // TODO: Replace with the latest appropriate version tag

  create_oidc_provider = true
  create_oidc_role     = true

  // Example: Allow any repository in 'my-org' or a specific branch in 'another-repo'
  repositories = [
    "my-org/*",
    "my-org/another-repo:ref:refs/heads/main"
  ]
  oidc_role_attach_policies = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]
}
```

### Audit Log Provider Usage

To use the GitHub Audit Log OIDC provider, you must specify `github_provider = "audit-log"` and provide your `enterprise_name`.

```hcl
module "github_oidc_audit_log" {
  source  = "terraform-module/github-oidc-provider/aws"
  version = "~> 1.0" // TODO: Replace with the latest appropriate version tag

  create_oidc_provider = true
  create_oidc_role     = true

  github_provider = "audit-log"
  enterprise_name = "MyGitHubEnterprise" // Replace with your actual enterprise name (case-sensitive)

  // Policies attached to the role that will be assumed by the audit log consumer
  oidc_role_attach_policies = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess" // Example policy with s3:PutObject permission
  ]
  // Note: The 'repositories' variable is not used when github_provider is 'audit-log'.
}
```

## Examples

See `examples` directory for working examples to reference

- [Examples Dir](https://github.com/terraform-module/module-blueprint/tree/master/examples/)

## Assumptions

## Available features

> **Note:** The Inputs and Outputs tables below are auto-generated. After making changes to variables, please run `terraform-docs .` or your pre-commit hooks to ensure this section is up-to-date with new variables like `github_provider` and `enterprise_name`.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
# AWS Github OIDC Provider Terraform Module

## Purpose
This module allows you to create a Github OIDC provider for your AWS account, that will help Github Actions to securely authenticate against the AWS API using an IAM role

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_openid_connect_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.attach](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_oidc_provider"></a> [create\_oidc\_provider](#input\_create\_oidc\_provider) | Whether or not to create the associated oidc provider. If false, variable 'oidc\_provider\_arn' is required | `bool` | `true` | no |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | ARN of the OIDC provider to use. Required if 'create_oidc_provider' is false | `string` | `null` | no |
| <a name="input_create_oidc_role"></a> [create\_oidc\_role](#input\_create\_oidc\_role) | Whether or not to create the OIDC attached role | `bool` | `true` | no |
| <a name="input_github_thumbprint"></a> [github\_thumbprint](#input\_github\_thumbprint) | GitHub OpenID TLS certificate thumbprint. | `string` | `"6938fd4d98bab03faadb97b34396831e3780aea1"` | no |
| <a name="input_max_session_duration"></a> [max\_session\_duration](#input\_max\_session\_duration) | Maximum session duration in seconds. | `number` | `3600` | no |
| <a name="input_oidc_role_attach_policies"></a> [oidc\_role\_attach\_policies](#input\_oidc\_role\_attach\_policies) | Attach policies to OIDC role. | `list(string)` | `[]` | no |
| <a name="input_repositories"></a> [repositories](#input\_repositories) | List of GitHub organization/repository names authorized to assume the role. | `list(string)` | `[]` | no |
| <a name="input_role_description"></a> [role\_description](#input\_role\_description) | (Optional) Description of the role. | `string` | `"Role assumed by the GitHub OIDC provider."` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | (Optional, Forces new resource) Friendly name of the role. | `string` | `"github-oidc-provider-aws"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to all resources | `map(string)` | `{}` | no |
| <a name="input_github_provider"></a> [github\_provider](#input\_github\_provider) | Type of GitHub OIDC provider to create. | `string` | `"actions"` | no |
| <a name="input_enterprise_name"></a> [enterprise\_name](#input\_enterprise\_name) | GitHub Enterprise name for audit log provider. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | OIDC provider ARN |
| <a name="output_oidc_role"></a> [oidc\_role](#output\_oidc\_role) | CICD GitHub role. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


### :memo: Guidelines

 - :memo: Use a succinct title and description.
 - :bug: Bugs & feature requests can be be opened
 - :signal_strength: Support questions are better asked on [Stack Overflow](https://stackoverflow.com/)
 - :blush: Be nice, civil and polite ([as always](http://contributor-covenant.org/version/1/4/)).

## License

Copyright 2022 Ivan Katliarhcuk

MIT Licensed. See [LICENSE](./LICENSE) for full details.

## How to Contribute

Submit a pull request

# Authors

Currently maintained by [Ivan Katliarchuk](https://github.com/ivankatliarchuk) and these [awesome contributors](https://github.com/terraform-module/terraform-aws-github-oidc-provider/graphs/contributors).

[![ForTheBadge uses-git](http://ForTheBadge.com/images/badges/uses-git.svg)](https://GitHub.com/)

## Terraform Registry

- [Module](https://registry.terraform.io/modules/terraform-module/github-oidc-provider/aws/latest)

## Resources

- [AWS: create oidc](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [Github: configure OIDC aws](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Github: OIDC cloud](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-cloud-providers)
- [AWS creds github action](https://github.com/aws-actions/configure-aws-credentials)
- [AWS Docs](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [Github OIDC](https://www.cloudquery.io/blog/keyless-access-to-aws-in-github-actions-with-oidc)
- [Terraform: oidc complex](https://github.com/SamuelBagattin/terraform-aws-github-oidc-provider)
- [Terraform: oidc simple](https://github.com/unfunco/terraform-aws-oidc-github)
- [Terraform: oidc](https://github.com/philips-labs/terraform-aws-github-oidc)

## Clone Me

[**Create a repository using this template →**][template.generate]

<!-- resources -->
[template.generate]: https://github.com/terraform-module/terraform-aws-github-oidc-provider/generate
