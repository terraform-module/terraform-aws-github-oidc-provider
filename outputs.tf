output "oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = local.oidc_provider_arn
}

output "oidc_role_arn" {
  description = "CICD GitHub role ARN"
  value       = local.role_arn
}

output "oidc_role_name" {
  description = "CICD GitHub role name"
  value       = local.role_name
}
