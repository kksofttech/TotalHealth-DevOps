output "cluster_name" {
  value = module.eks.cluster_id
}

output "kubeconfig" {
  value     = module.eks.kubeconfig
  sensitive = true
}

output "ecr_patient" {
  value = aws_ecr_repository.patient.repository_url
}

output "ecr_appointment" {
  value = aws_ecr_repository.appointment.repository_url
}

