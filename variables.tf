variable "create_oidc_provider" {
  description = "Whether or not to create the associated oidc provider. If false, variable 'oidc_provider_arn' is required"
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider to use. Required if 'create_oidc_provider' is false"
  type        = string
  default     = null
}

variable "create_oidc_role" {
  description = "Whether or not to create the OIDC attached role"
  type        = bool
  default     = true
}

# Refer to the README for information on obtaining the thumbprint.
# This is specified as a variable to allow it to be updated quickly if it is
# unexpectedly changed by GitHub.
# See: https://github.blog/changelog/2022-01-13-github-actions-update-on-oidc-based-deployments-to-aws/
variable "github_thumbprint" {
  description = "GitHub OpenID TLS certificate thumbprint."
  type        = string
  default     = "6938fd4d98bab03faadb97b34396831e3780aea1"
}

variable "repositories" {
  description = <<-EOT
    List of GitHub organization/repository names authorized to assume the role.
    Both the classic name-based format (`organization/repository`) and the
    immutable subject format that GitHub issues for repositories created or
    transferred after 2026-07-15 (`organization@owner-id/repository@repo-id`)
    are supported.
    See https://docs.github.com/en/actions/reference/security/oidc#immutable-subject-claims.
  EOT
  type        = list(string)
  default     = []

  validation {
    # Ensures each element of the repositories list matches either the classic
    # `organization/repository` format or the immutable-subject format
    # `organization@owner-id/repository@repo-id` that GitHub uses for the
    # `sub` claim of repositories created/transferred after 2026-07-15.
    # An optional trailing context (e.g. `:ref:refs/heads/main`, `:*`) is allowed.
    condition = length([
      for repo in var.repositories : 1
      if length(regexall("^[A-Za-z0-9_.-]+(@[0-9]+)?/([A-Za-z0-9_.:/@-]+|\\*)$", repo)) > 0
    ]) == length(var.repositories)
    error_message = "Repositories must be specified in the organization/repository or immutable organization@owner-id/repository@repo-id format."
  }
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "Maximum session duration must be between 3600 and 43200 seconds."
  }
}

variable "oidc_role_attach_policies" {
  description = "Attach policies to OIDC role."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "A mapping of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

variable "role_name" {
  description = "(Optional, Forces new resource) Friendly name of the role."
  type        = string
  default     = "github-oidc-provider-aws"
}

variable "role_description" {
  description = "(Optional) Description of the role."
  type        = string
  default     = "Role assumed by the GitHub OIDC provider."
}
