resource "aws_autoscaling_group" "asg" {
  name = "${var.project_name}-asg"

  desired_capacity = var.auto_scaling_group.desired_size
  max_size         = var.auto_scaling_group.max_size
  min_size         = var.auto_scaling_group.min_size

  vpc_zone_identifier = module.vpc.private_subnets
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = aws_launch_template.launch_template.latest_version
  }

  target_group_arns = [
    var.app.allow_http_access ? aws_lb_target_group.http_tg[0].arn : "",
    var.app.allow_https_access ? aws_lb_target_group.https_tg[0].arn : ""
  ]
  # health_check_grace_period = 30
  health_check_type = "ELB" # or "EC2"
  instance_refresh {
    strategy = "Rolling"
  }
}

# --
resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = var.alb_deletion_protection

  #   access_logs {
  #     bucket  = aws_s3_bucket.lb_logs.bucket
  #     prefix  = "test-lb"
  #     enabled = true
  #   }

  tags = {
    Environment = "production"
  }
}

# --- HTTP Listener and TG ---

resource "aws_lb_target_group" "http_tg" {
  count    = var.app.allow_http_access ? 1 : 0
  name     = "${var.project_name}-http-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb_listener" "http_lb_listner" {
  count             = var.app.allow_http_access ? 1 : 0
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http_tg[0].arn
  }
  tags = {
    "Name" = "${var.project_name}-http_lb_listner"
  }
}

# --- HTTPS Listener and TG ---

resource "aws_lb_target_group" "https_tg" {
  count    = var.app.allow_https_access ? 1 : 0
  name     = "${var.project_name}-https-tg"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb_listener" "https_lb_listner" {
  count             = var.app.allow_https_access ? 1 : 0
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.app.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.https_tg[0].arn
  }
  tags = {
    "Name" = "${var.project_name}-https_lb_listner"
  }
}

# --- Security Group ---

resource "aws_security_group" "lb_sg" {
  name        = "${var.project_name}-lb_sg"
  description = "Allow HTTP/HTTPS inbound traffic"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-lb_sg"
  }
}

resource "aws_security_group_rule" "lb_sg-http_from_elb" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  security_group_id = aws_security_group.lb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group_rule" "lb_sg-https_from_elb" {
  type              = "ingress"
  from_port         = 443
  to_port           = 80
  protocol          = "TCP"
  security_group_id = aws_security_group.lb_sg.id
  cidr_blocks       = ["0.0.0.0/0"]

  lifecycle { create_before_destroy = true }
}
