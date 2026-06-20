variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "The name of the VPC."
  type        = string
  default     = "my-vpc"
}

variable "project" {
  description = "The project name."
  type        = string
  default     = "my-project"
}

variable "environment" {
  description = "The environment name."
  type        = string
  default     = "dev"
}

