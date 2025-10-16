###################################
# Output
###################################
output "worker_sg_id" {
  value       = aws_security_group.worker_sg.id
  description = "Security Group ID of the EKS worker nodes"
}