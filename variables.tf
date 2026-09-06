variable "aws_region" {
  description = "AWS Region where the lab will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix used for lab resources."
  type        = string
  default     = "imds-lab"
}

variable "allowed_cidr" {
  description = "Public IPv4 CIDR allowed to reach the vulnerable test app on TCP/8080. Use your public IP with /32."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.allowed_cidr))
    error_message = "allowed_cidr must be a valid IPv4 CIDR, for example 203.0.113.10/32."
  }
}

variable "instance_type" {
  description = "EC2 instance type used by the lab."
  type        = string
  default     = "t3.nano"
}

variable "http_tokens" {
  description = "IMDS token requirement. Start with optional, then change to required during the migration test."
  type        = string
  default     = "optional"

  validation {
    condition     = contains(["optional", "required"], var.http_tokens)
    error_message = "http_tokens must be either optional or required."
  }
}

variable "iam_role_name" {
  description = "IAM role attached to the EC2 instance."
  type        = string
  default     = "IMDSLabRole"
}
