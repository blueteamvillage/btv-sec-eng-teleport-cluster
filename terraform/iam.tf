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
  name               = "${var.PROJECT_PREFIX}-teleport-cluster"
  assume_role_policy = "${var.teleport_app_serv_role_policy}"

  tags = {
    Project = var.PROJECT_PREFIX
  }
}

############################################ IAM Profile ############################################
resource "aws_iam_instance_profile" "teleport" {
  name       = "${var.PROJECT_PREFIX}-teleport-cluster"
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
  name   = "${var.PROJECT_PREFIX}-teleport-cluster-ec2"
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
}

resource "aws_iam_role_policy" "s3" {
  name   = "${var.PROJECT_PREFIX}-teleport-cluster-s3"
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
  name   = "${var.PROJECT_PREFIX}-teleport-cluster-dynamo"
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
  name   = "${var.PROJECT_PREFIX}-teleport-cluster-route53"
  role   = aws_iam_role.teleport.id
  policy = data.aws_iam_policy_document.route53.json
}
