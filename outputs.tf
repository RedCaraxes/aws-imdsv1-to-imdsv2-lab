output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.lab.id
}

output "public_ip" {
  description = "Public IPv4 address of the lab instance."
  value       = aws_instance.lab.public_ip
}

output "iam_role_name" {
  description = "IAM role exposed through the instance metadata service."
  value       = aws_iam_role.lab.name
}

output "lab_url" {
  description = "Base URL for the lab application."
  value       = "http://${aws_instance.lab.public_ip}:8080"
}

output "test_commands" {
  description = "Commands used during the lab."
  value = {
    health = "curl http://${aws_instance.lab.public_ip}:8080/health"

    legacy_imdsv1 = "curl http://${aws_instance.lab.public_ip}:8080/legacy"

    valid_imdsv2 = "curl http://${aws_instance.lab.public_ip}:8080/v2"

    ssrf_instance_id = "curl \"http://${aws_instance.lab.public_ip}:8080/fetch?url=http://169.254.169.254/latest/meta-data/instance-id\""

    ssrf_role_name = "curl \"http://${aws_instance.lab.public_ip}:8080/fetch?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/\""
  }
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard with MetadataNoToken and MetadataNoTokenRejected."
  value       = aws_cloudwatch_dashboard.imds.dashboard_name
}
