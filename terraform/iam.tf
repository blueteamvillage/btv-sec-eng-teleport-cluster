/*
An IAM Role and Policies are used to permit
EC2 instances to communicate with various AWS
resources.
*/

############################################ IAM Role ############################################
data "aws_iam_policy_document" "teleport" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "teleport" {
  name               = var.teleport_ec2_role_name
  assume_role_policy = var.teleport_app_serv_role_policy

  tags = {
    Name                       = var.teleport_ec2_role_name
    Project                    = var.PROJECT_PREFIX
    "teleport.dev/origin"      = "integration_awsoidc"
    "teleport.dev/cluster"     = "teleport.blueteamvillage.org"
    "teleport.dev/integration" = "defcon-2024-obsidian-teleport-enroll-ec2"
  }
}

############################################ IAM Profile ############################################
resource "aws_iam_instance_profile" "teleport" {
  name       = var.teleport_ec2_role_name
  role       = aws_iam_role.teleport.name
  depends_on = [aws_iam_role_policy.s3]
}

// Policy attatchment to permit SSM functionality
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.teleport.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


// Policy to permit cluster to check EC2 nodes attempting to join
data "aws_iam_policy_document" "ec2" {
  version = "2012-10-17"
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ec2" {
  name   = "${var.teleport_ec2_role_name}_EC2"
  role   = aws_iam_role.teleport.id
  policy = data.aws_iam_policy_document.ec2.json
}

// Policy to permit cluster to talk to S3 (Session recordings)
data "aws_iam_policy_document" "s3" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:ListBucketMultipartUploads",
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.teleport.bucket}"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:AbortMultipartUpload",
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.teleport.bucket}/records/*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:CreateBucket"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "s3" {
  name   = "${var.teleport_ec2_role_name}_S3"
  role   = aws_iam_role.teleport.id
  policy = data.aws_iam_policy_document.s3.json
}


// Policy to permit cluster to access DynamoDB tables (Cluster state, events, and SSL)

data "aws_iam_policy_document" "dynamo" {
  version = "2012-10-17"
  statement {
    sid       = "AllActionsOnTeleportDB"
    effect    = "Allow"
    actions   = ["dynamodb:*"]
    resources = [aws_dynamodb_table.teleport.arn]
  }
  statement {
    sid       = "AllActionsOnTeleportStreamsDB"
    effect    = "Allow"
    actions   = ["dynamodb:*"]
    resources = ["${aws_dynamodb_table.teleport.arn}/stream/*"]
  }
  statement {
    sid       = "AllActionsOnTeleportEventsDB"
    effect    = "Allow"
    actions   = ["dynamodb:*"]
    resources = [aws_dynamodb_table.teleport_events.arn]
  }
  statement {
    sid       = "AllActionsOnTeleportEventsIndexDB"
    effect    = "Allow"
    actions   = ["dynamodb:*"]
    resources = ["${aws_dynamodb_table.teleport_events.arn}/index/*"]
  }
  statement {
    sid       = "AllActionsOnLocks"
    effect    = "Allow"
    actions   = ["dynamodb:*"]
    resources = [aws_dynamodb_table.teleport_locks.arn]
  }

}

resource "aws_iam_role_policy" "dynamo" {
  name   = "${var.teleport_ec2_role_name}_DYNAMO"
  role   = aws_iam_role.teleport.id
  policy = data.aws_iam_policy_document.dynamo.json
}

data "aws_iam_policy_document" "route53" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:GetChange",
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = ["arn:aws:route53:::hostedzone/${var.route53_zone_id}"]
  }
}

// Policy to permit cluster to access Route53 (SSL)
resource "aws_iam_role_policy" "route53" {
  name   = "${var.teleport_ec2_role_name}_ROUTE53"
  role   = aws_iam_role.teleport.id
  policy = data.aws_iam_policy_document.route53.json
}

// Policy to permit cluster to access IAM (OIDC)
data "aws_iam_policy_document" "teleport_oidc" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "iam:CreateOpenIDConnectProvider",
      "iam:TagOpenIDConnectProvider",
      "iam:GetRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:PutRolePolicy"
    ]
    resources = ["*"]
  }
}

// Policy to permit cluster to access IAM (OIDC)
resource "aws_iam_role_policy" "teleport_oidc" {
  name   = "${var.teleport_ec2_role_name}_OIDC"
  role   = aws_iam_role.teleport.id
  policy = data.aws_iam_policy_document.teleport_oidc.json
}

// Policy to permit cluster to access SSM (Session recordings)
data "aws_iam_policy_document" "teleport_ssm" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "ssm:CreateDocument"
    ]
    resources = ["*"]
  }
}

// Policy to permit cluster to access SSM (Session recordings)
resource "aws_iam_role_policy" "teleport_ssm" {
  name   = "${var.teleport_ec2_role_name}_SSM"
  role   = aws_iam_role.teleport.id
  policy = data.aws_iam_policy_document.teleport_ssm.json
}
