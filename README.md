# EKS Hackathon Demo

This repository contains a sample two-microservice Node.js application (Patient & Appointment) and the IaC / CI/CD pipeline to deploy it to AWS EKS.

## Structure
See repo layout in the root of the repository.

## How to run (high-level)
1. Add GitHub Secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION` = `ap-south-1`
   - `AWS_ACCOUNT_ID` = `390844470549`
2. (Optional) Create ACM certificate in ap-south-1 and update `k8s/ingress-alb.yaml` annotation `alb.ingress.kubernetes.io/certificate-arn`.
3. Push to `main`. GitHub Actions will:
   - Run Terraform apply to create VPC, EKS and ECR.
   - Build and push Docker images to ECR.
   - Deploy Kubernetes manifests to EKS (apply k8s/).
4. Confirm resources and check logs in CloudWatch (Container Insights recommended).

## Notes
- The ingress uses AWS Load Balancer Controller (ALB). Install the controller in the cluster (helm chart) after cluster creation. See AWS docs: https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
- Replace the ACM ARN and DNS host in the ingress manifest for TLS.
- Use GitHub OIDC for short-lived credentials (recommended).

## Useful commands (local)
- `terraform -chdir=infra/envs/dev init`
- `terraform -chdir=infra/envs/dev apply -auto-approve`
- `aws eks update-kubeconfig --region ap-south-1 --name hackathon-eks-cluster`
- `kubectl get all -n services`

