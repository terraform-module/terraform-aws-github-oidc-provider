/**
 * # AWS Github OIDC Provider Terraform Module
 *
 * ## Purpose
 * This module allows you to create a Github OIDC provider for your AWS account, that will help Github Actions to securely authenticate against the AWS API using an IAM role
 *
*/
resource "aws_iam_openid_connect_provider" "this" {
  count = var.create_oidc_provider ? 1 : 0
  client_id_list = [
    "sts.amazonaws.com",
  ]
  thumbprint_list = [var.github_thumbprint]
  url             = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "this" {
  count                = var.create_oidc_role ? 1 : 0
  name                 = var.role_name
  description          = var.role_description
  max_session_duration = var.max_session_duration
  assume_role_policy   = join("", data.aws_iam_policy_document.this[0].*.json)
  tags                 = var.tags
  # path                  = var.iam_role_path
  # permissions_boundary  = var.iam_role_permissions_boundary
  depends_on = [aws_iam_openid_connect_provider.this]
}

resource "aws_iam_role_policy_attachment" "attach" {
  count = var.create_oidc_role ? length(var.oidc_role_attach_policies) : 0

  policy_arn = var.oidc_role_attach_policies[count.index]
  role       = join("", aws_iam_role.this.*.name)

  depends_on = [aws_iam_role.this]
}

data "aws_iam_policy_document" "this" {
  count = var.create_oidc_role ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test   = "StringLike"
      values = [
        for repo in var.repositories :
        "repo:%{if length(regexall(":+", repo)) > 0}${repo}%{else}${repo}:*%{endif}"
      ]
      variable = "token.actions.githubusercontent.com:sub"
    }

    principals {
      identifiers = [try(aws_iam_openid_connect_provider.this[0].arn, var.oidc_provider_arn)]
      type        = "Federated"
    }
  }
}
