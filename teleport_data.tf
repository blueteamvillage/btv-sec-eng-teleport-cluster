data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "base" {
  most_recent = true
  owners      = [126027368216]

  filter {
    name   = "name"
    values = [var.ami_name]
  }
}

data "aws_route53_zone" "cluster" {
  name = var.route53_zone
}

data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
  name = var.region
}

// SSM is picking alias for key to use for encryption in SSM
data "aws_kms_alias" "ssm" {
  name = var.kms_alias_name
}
