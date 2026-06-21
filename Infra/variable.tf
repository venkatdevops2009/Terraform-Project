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

variable "ami_id" {
  description = "The AMI ID for the EC2 instances."
  type        = string
  default     = "ami-0220d79f3f480ecf5" # Replace with your desired AMI ID
}

variable "instance_type" {
  description = "The instance type for the EC2 instances."
  type        = string
  default     = "t3.micro" # Replace with your desired instance type
}
