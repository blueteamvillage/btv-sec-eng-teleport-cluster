resource "aws_secretsmanager_secret" "github_oauth_secret" {
  name = "${var.teleport_ec2_role_name}_GITHUB_OAUTH_SECRET"

  tags = {
    Project = var.PROJECT_PREFIX
  }
}
