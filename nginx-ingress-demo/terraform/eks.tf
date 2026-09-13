# =============================================================================
# eks.tf
# =============================================================================
# Creates the EKS cluster and managed node groups.
#
# WHAT IS EKS?
#   AWS managed Kubernetes control plane. AWS manages the master nodes
#   (API server, etcd, scheduler). You only manage worker nodes.
#
# COMPONENTS CREATED:
#   - EKS Control Plane (managed by AWS)
#   - Managed Node Group (EC2 worker nodes in private subnets)
#   - EKS Add-ons (CoreDNS, kube-proxy, VPC CNI, EBS CSI)
#   - OIDC Provider (required for IAM Roles for Service Accounts - IRSA)
#
# IRSA (IAM Roles for Service Accounts):
#   Allows K8s pods to assume IAM roles WITHOUT storing AWS credentials.
#   AWS LBC pod uses IRSA to call AWS APIs (create ALB, target groups etc.)
#
# NODE GROUP IN PRIVATE SUBNETS:
#   Worker nodes are in private subnets. They can reach internet via NAT
#   but internet cannot directly reach them. ALB forwards traffic to them.
# =============================================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project_name}-eks"
  cluster_version = var.eks_cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets   # nodes in private subnets

  # ---------------------------------------------------------------------------
  # Cluster Access
  # ---------------------------------------------------------------------------
  # cluster_endpoint_public_access = true allows kubectl from your laptop.
  # In strict prod, set to false and use VPN/bastion to access.
  # ---------------------------------------------------------------------------
  cluster_endpoint_public_access = true

  # ---------------------------------------------------------------------------
  # OIDC Provider
  # ---------------------------------------------------------------------------
  # Enables IRSA — pods can assume IAM roles via service accounts.
  # Required for AWS LBC, Cluster Autoscaler, EBS CSI driver etc.
  # ---------------------------------------------------------------------------
  enable_irsa = true

  # ---------------------------------------------------------------------------
  # EKS Managed Add-ons
  # ---------------------------------------------------------------------------
  # These are AWS-managed K8s components, auto-updated by AWS.
  # coredns      → DNS resolution inside cluster
  # kube-proxy   → Network rules on each node
  # vpc-cni      → AWS VPC networking for pods (each pod gets a VPC IP)
  # aws-ebs-csi-driver → Allows pods to use EBS volumes as PersistentVolumes
  # ---------------------------------------------------------------------------
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # ---------------------------------------------------------------------------
  # Managed Node Groups
  # ---------------------------------------------------------------------------
  # AWS manages the EC2 instances, auto-scaling, AMI updates.
  # Nodes are in private subnets — no direct internet exposure.
  # ---------------------------------------------------------------------------
  eks_managed_node_groups = {
    main = {
      name           = "${var.project_name}-nodes"
      instance_types = [var.eks_node_instance_type]

      min_size     = var.eks_node_min_size
      max_size     = var.eks_node_max_size
      desired_size = var.eks_node_desired_size

      # Nodes in private subnets only
      subnet_ids = module.vpc.private_subnets

      # Use latest EKS-optimized AMI
      ami_type = "AL2_x86_64"

      # Disk size for each node
      disk_size = 50

      labels = {
        role = "worker"
      }

      tags = {
        Name = "${var.project_name}-node"
      }
    }
  }

  tags = {
    Name = "${var.project_name}-eks"
  }
}
