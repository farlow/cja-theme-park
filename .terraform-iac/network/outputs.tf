output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_nets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}

output "private_nets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}
output "private_subnets_ids" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnets
}

output "target_group_arn" {
  description = "Target group ARN"
  value = aws_lb_target_group.app-nlb-target-group.arn
}
