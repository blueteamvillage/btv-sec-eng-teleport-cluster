############################################ Security group ############################################
resource "aws_security_group" "teleport_cluster" {
  name        = "${var.teleport_ec2_role_name}_SG"
  description = "${var.teleport_ec2_role_name} Security Group"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.teleport_ec2_role_name}_SG"
    Project = var.PROJECT_PREFIX
  }
}

resource "aws_security_group_rule" "sshd" {
  description       = "SSH port to allow IaC from us-west-2"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["18.237.140.160/29"]
  security_group_id = aws_security_group.teleport_cluster.id
}

resource "aws_security_group_rule" "web_interface" {
  description       = "In TLS Routing mode, the Proxy handles all protocols, including Web UI, HTTPS, Kubernetes, SSH, and all databases on a single port."
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.teleport_cluster.id
}

resource "aws_security_group_rule" "ssh_proxy_ansible" {
  description       = "SSH port. This is Teleports equivalent of port 22 for SSH. Only used when Teleport Node is replacing SSH."
  type              = "ingress"
  from_port         = 2022
  to_port           = 2022
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.teleport_cluster.id
}

resource "aws_security_group_rule" "proxy" {
  description       = "Port used by Teleport Proxy Service instances to dial agents in Proxy Peering mode."
  type              = "ingress"
  from_port         = 3021
  to_port           = 3021
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.teleport_cluster.id
}

resource "aws_security_group_rule" "ssh_proxy" {
  description       = "SSH port. This is Teleports equivalent of port 22 for SSH. Only used when Teleport Node is replacing SSH."
  type              = "ingress"
  from_port         = 3022
  to_port           = 3022
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.teleport_cluster.id
}

resource "aws_security_group_rule" "auth_proxy" {
  description       = "TLS port used by the Auth Service to serve its API to other Nodes in a cluster."
  type              = "ingress"
  from_port         = 3025
  to_port           = 3025
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.teleport_cluster.id
}

resource "aws_security_group_rule" "rdp_proxy" {
  description       = "When using Desktop Service windows_desktop_service.listen_addr"
  type              = "ingress"
  from_port         = 3028
  to_port           = 3028
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.teleport_cluster.id
}

resource "aws_security_group_rule" "outbound" {
  description       = "Allow egress traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.teleport_cluster.id
}

############################################ EC2 ############################################
resource "aws_instance" "teleport" {
  key_name               = var.public_key_name
  ami                    = var.teleport_ami
  instance_type          = var.instance_type
  subnet_id              = var.teleport_subnet_id
  vpc_security_group_ids = [aws_security_group.teleport_cluster.id]
  iam_instance_profile   = aws_iam_role.teleport.id

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted             = true
    volume_size           = 40
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags = {
    Name    = var.ec2_name
    Project = var.PROJECT_PREFIX
  }
}

resource "aws_eip" "telelport" {
  instance = aws_instance.teleport.id

  tags = {
    Project = var.PROJECT_PREFIX
  }
}
