// Auth, node, proxy (aka Teleport Cluster) on single AWS instance
resource "aws_instance" "cluster" {
  key_name                    = var.public_key_name
  ami                         = data.aws_ami.base.id
  instance_type               = var.cluster_instance_type
  subnet_id                   = tolist(data.aws_subnets.all.ids)[0]
  vpc_security_group_ids      = [aws_security_group.cluster.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_role.cluster.id

  user_data = data.cloudinit_config.cluster_user_data.rendered

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted = true
  }
}

locals {
  teleport_conf = <<-END
    #cloud-config
    ${jsonencode({
      write_files = [
        {
          path        = "/etc/teleport.d/conf"
          permissions = "0644"
          owner       = "root:root"
          encoding    = "b64"
          content     = base64encode(templatefile(
            "${path.module}/user_data/teleport_cluster_conf.tpl",
            {
              region                   = var.region
              cluster_name             = var.cluster_name
              email                    = var.email
              domain_name              = var.route53_domain
              dynamo_table_name        = aws_dynamodb_table.teleport.name
              dynamo_events_table_name = aws_dynamodb_table.teleport_events.name
              locks_table_name         = aws_dynamodb_table.teleport_locks.name
              license_path             = var.license_path
              s3_bucket                = var.s3_bucket_name
              enable_mongodb_listener  = var.enable_mongodb_listener
              enable_mysql_listener    = var.enable_mysql_listener
              enable_postgres_listener = var.enable_postgres_listener
              use_acm                  = var.use_acm
              use_letsencrypt          = var.use_letsencrypt
              aws_account_id           = data.aws_caller_identity.current.account_id
           }))
        },
      ]
    })}
  END
}

data "cloudinit_config" "cluster_user_data" {
  gzip          = true
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    filename     = "conf"
    content      = local.teleport_conf
  }
}
