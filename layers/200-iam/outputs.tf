# SSM + Ansible Role Outputs
output "ssm_ansible_role_arn" {
  description = "ARN of the SSM + Ansible EC2 role"
  value       = aws_iam_role.ssm_ansible_role.arn
}

output "ssm_ansible_role_name" {
  description = "Name of the SSM + Ansible EC2 role"
  value       = aws_iam_role.ssm_ansible_role.name
}

output "ssm_ansible_instance_profile_name" {
  description = "Name of the SSM + Ansible instance profile"
  value       = aws_iam_instance_profile.ssm_ansible_profile.name
}

output "ssm_ansible_instance_profile_arn" {
  description = "ARN of the SSM + Ansible instance profile"
  value       = aws_iam_instance_profile.ssm_ansible_profile.arn
}
