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
  name        = "${var.project_name}-ReadOnlyAcessToECR"
  description = "Read only to ECR"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:Get*",
          "ecr:List*",
          "ecr:Describe*",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ],
        #! 전체 ECR에 접근할 수 있는 권한을 줌
        Resource = "arn:aws:ecr:*:*:repository/*"
      },
      {
        Effect   = "Allow",
        Action   = "ecr:GetAuthorizationToken",
        Resource = "*"
      }
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
  name = aws_iam_role.ec2_role.name
  role = aws_iam_role.ec2_role.name
}



