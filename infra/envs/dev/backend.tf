terraform {
  backend "s3" {
    bucket         = "eks-hackathon-tfstate-390844470549"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "eks-hackathon-tf-locks"
  }
}

