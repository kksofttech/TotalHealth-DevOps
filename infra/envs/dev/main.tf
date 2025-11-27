terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

# VPC (simple)
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr
  tags = { Name = "${var.cluster_name}-vpc" }
}

resource "aws_subnet" "public" {
  for_each = toset(var.public_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = data.aws_availability_zones.available.names[length(split(",", join(",", var.public_subnets))) > 1 ? index(data.aws_availability_zones.available.names, data.aws_availability_zones.available.names[0]) : 0] # placeholder
  tags = { Name = "${var.cluster_name}-public-${each.key}" }
}

resource "aws_subnet" "private" {
  for_each = toset(var.private_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  tags = { Name = "${var.cluster_name}-private-${each.key}" }
}

# Internet Gateway for public subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.cluster_name}-igw" }
}

# Simple route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.cluster_name}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# ECR repositories
resource "aws_ecr_repository" "patient" {
  name = "patient-service"
  image_scanning_configuration { scan_on_push = true }
  tags = { project = "hackathon" }
}

resource "aws_ecr_repository" "appointment" {
  name = "appointment-service"
  image_scanning_configuration { scan_on_push = true }
  tags = { project = "hackathon" }
}

# IAM role for EKS (basic)
resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
}

data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_service_attach" {
  for_each = {
    "AmazonEKSClusterPolicy" = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    "AmazonEKSServicePolicy" = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  }
  role       = aws_iam_role.eks_cluster.name
  policy_arn = each.value
}

# EKS cluster using module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 18.0.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.28"
  subnets         = aws_subnet.private[*].id
  vpc_id          = aws_vpc.this.id

  node_groups = {
    ng1 = {
      desired_capacity = 2
      max_capacity     = 3
      instance_types   = ["t3.medium"]
    }
  }

  manage_aws_auth = true
}

# S3 bucket for state (in case you need it via Terraform)
resource "aws_s3_bucket" "tfstate" {
  bucket = "eks-hackathon-tfstate-390844470549"
  acl    = "private"
  versioning { enabled = true }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = { Name = "eks-hackathon-tfstate" }
}

# DynamoDB table for locking
resource "aws_dynamodb_table" "tf_locks" {
  name         = "eks-hackathon-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

output "cluster_name" {
  value = module.eks.cluster_id
}

output "kubeconfig" {
  value = module.eks.kubeconfig
  sensitive = true
}

output "ecr_patient" {
  value = aws_ecr_repository.patient.repository_url
}

output "ecr_appointment" {
  value = aws_ecr_repository.appointment.repository_url
}

