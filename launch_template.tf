locals {
  image_url = "%{if var.image.registry != ""}${var.image.registry}/%{endif}${var.image.repository}:${var.image.tag}"
  http_port = "-p 80:${var.app.port}"
}

resource "aws_launch_template" "launch_template" {
  name                   = "${var.project_name}-launch_template"
  update_default_version = var.launch_template.update_default_version

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = var.launch_template.ebs_volume_size
      volume_type = var.launch_template.ebs_type
    }
  }

  credit_specification { cpu_credits = "standard" }
  iam_instance_profile { name = aws_iam_instance_profile.profile.name }

  # disable_api_termination = true # 종료 방지 기능

  image_id                             = "ami-0cbec04a61be382d9"
  instance_initiated_shutdown_behavior = "terminate"

  instance_type = var.launch_template.ec2_type
  # key_name      = # Bastion host로 들어올 때 필요

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  vpc_security_group_ids = [aws_security_group.allow_elb.id]
  user_data              = base64encode(data.template_file.user_data.rendered)
}

# If error on 'tf init', check https://www.binaryflavor.com/m1-baineoriga-jegongdoeji-anhneun/
data "template_file" "user_data" {
  template = <<-EOT
    #!/bin/bash
    sudo yum update -y
    sudo yum upgrade -y

    # For connection via AWS System Manager
    cd /tmp
    sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
    sudo systemctl enable amazon-ssm-agent
    sudo systemctl start amazon-ssm-agent

    # Install Docker
    sudo yum install docker -y
    sudo systemctl enable docker.service
    sudo systemctl start docker.service

    # Login and run docker container
    sudo aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.image.registry}
    sudo docker run --name application ${local.http_port} -d ${local.image_url}
  EOT
}

resource "aws_security_group" "allow_elb" {
  name        = "allow_elb"
  description = "Allow inbound traffic from ELB"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_elb"
  }
}

resource "aws_security_group_rule" "allow_elb-http_from_elb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  security_group_id        = aws_security_group.allow_elb.id
  source_security_group_id = aws_security_group.lb_sg.id
}

resource "aws_security_group_rule" "allow_elb-https_from_elb" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "TCP"
  security_group_id        = aws_security_group.allow_elb.id
  source_security_group_id = aws_security_group.lb_sg.id
}

