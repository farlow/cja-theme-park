variable "vpc_cidr" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "app" {
  description = "App name"
}

variable "private_subnets" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "cloudns_auth_id" {
  description = "Cloudns auth id"
}

variable "cloudns_password" {
  description = "Cloudns password"
}