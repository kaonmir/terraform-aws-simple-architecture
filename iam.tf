data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "ssm_access_ec2" {
  name = "AmazonEC2RoleforSSM"
}

resource "aws_iam_policy" "ec2_access_ecr" {
  name        = "FullAcessToECR"
  description = "Full Access to ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["ecr:*"]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "ec2_role" {
  name               = "${var.project_name}-EC2Role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
  managed_policy_arns = [
    data.aws_iam_policy.ssm_access_ec2.arn,
    aws_iam_policy.ec2_access_ecr.arn
  ]
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.project_name}-instance_profile"
  role = aws_iam_role.ec2_role.name
}
