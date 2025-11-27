variable "region" {
  description = "AWS Region"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  type    = string
  default = "hackathon-eks-cluster"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type = list(string)
  default = ["10.0.1.0/24","10.0.2.0/24"]
}

variable "private_subnets" {
  type = list(string)
  default = ["10.0.11.0/24","10.0.12.0/24"]
}

variable "account_id" {
  type    = string
  default = "390844470549"
}

