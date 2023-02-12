############################################ General ############################################
variable "PROJECT_PREFIX" {
  description = "Prefix that is appended to all resources"
  type        = string
}

variable "primary_region" {
  description = "Region to create resources in"
  type        = string
}

variable "ubunut-ami" {
  # Ubuntu 22.04
  # https://cloud-images.ubuntu.com/locator/ec2/
  description = "Ubuntu 22.04 LTS AMI"
  type        = string
  default     = "ami-0ab0629dba5ae551d"
}

variable "instance_type" {
  description = "Instance size to create"
  type        = string
  default     = "t3.small"
}

variable "public_key_name" {
  description = "Name of SSH public key to use"
  type        = string
}

############################################ Route 53 ############################################
variable "route53_zone_id" {
  description = "Route 53 Zone ID to create DNS records for Teleport"
  type        = string
}

variable "route53_domain" {
  description = "Route 53 domain for Teleport"
  type        = string
}

############################################ Networking ############################################
variable "vpc_id" {
  description = "ID of VPC for Teleport"
  type        = string
}

variable "teleport_subnet_id" {
  description = "Subnet ID for Teleport"
  type        = string
}
