variable "app" {
  description = "App name"
}

variable "vpc_id" {
  description = "VPC Id"
}

variable "public_nets" {
  description = "List of IDs of public subnets"
}

variable "instance_types" {
  description = "instance type for EKS worker"
}

variable "ami_type" {
  description = "AMI type"
}

variable "account_id" {
  description = "AWS Account ID"
}

variable "user1" {
  description = "IAM user1"
}

variable "user2" {
  description = "IAM user2"
}

variable "user3" {
  description = "IAM user3"
}

variable "user4" {
  description = "IAM user4"
}

variable "target_group_arn" {
  description = "Target group ARN"
}

variable "cluster_issuer_email" {
  description = "email for letsencrypt"
}