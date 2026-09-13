# =============================================================================
# iam.tf
# =============================================================================
# IAM roles and policies for AWS Load Balancer Controller (AWS LBC).
#
# WHY DOES AWS LBC NEED IAM?
#   AWS LBC is a pod running inside EKS. When it sees an Ingress resource
#   with ALB annotations, it calls AWS APIs to:
#     - Create/delete ALBs
#     - Create/delete Target Groups
#     - Register/deregister EC2 instances as targets
#     - Create/delete listener rules
#
#   For this, it needs AWS permissions — but we NEVER put AWS credentials
#   inside pods. Instead we use IRSA (IAM Roles for Service Accounts).
#
# HOW IRSA WORKS:
#   1. EKS has an OIDC provider (created in eks.tf)
#   2. We create an IAM role that trusts this OIDC provider
#   3. The trust policy says: "only the aws-load-balancer-controller
#      service account in kube-system namespace can assume this role"
#   4. AWS LBC pod uses this service account → gets temporary credentials
#   5. No static credentials stored anywhere
#
# FLOW:
#   AWS LBC Pod → K8s Service Account → OIDC → IAM Role → AWS APIs
# =============================================================================

# -----------------------------------------------------------------------------
# Download the official AWS LBC IAM policy from AWS
# -----------------------------------------------------------------------------
# This is the official policy document maintained by AWS.
# It contains all permissions AWS LBC needs to manage ALBs.
# -----------------------------------------------------------------------------
data "http" "aws_lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.1/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "aws_lbc" {
  name        = "${var.project_name}-aws-lbc-policy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = data.http.aws_lbc_iam_policy.response_body
}

# -----------------------------------------------------------------------------
# IAM Role for AWS LBC (IRSA)
# -----------------------------------------------------------------------------
# Trust policy allows only the specific K8s service account to assume this role.
# This is the IRSA pattern — scoped to exact namespace + service account name.
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "aws_lbc_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    # Only allow the specific service account to assume this role
    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "aws_lbc" {
  name               = "${var.project_name}-aws-lbc-role"
  assume_role_policy = data.aws_iam_policy_document.aws_lbc_assume_role.json

  tags = {
    Name = "${var.project_name}-aws-lbc-role"
  }
}

resource "aws_iam_role_policy_attachment" "aws_lbc" {
  role       = aws_iam_role.aws_lbc.name
  policy_arn = aws_iam_policy.aws_lbc.arn
}
