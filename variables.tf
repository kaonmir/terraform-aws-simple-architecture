variable "aws_region" {
  type = string
}

variable "number_of_subnet" {
  type    = number
  default = 2
}

variable "project_name" {
  type = string
}

variable "launch_template" {
  type = object({
    ec2_type               = string
    ebs_type               = string
    ebs_volume_size        = number
    extra_user_data        = string
    update_default_version = bool
  })
  description = "Launch Template을 생성 혹은 갱신한다. "
  default = {
    ec2_type               = "t3.small"
    ebs_type               = "gp2"
    ebs_volume_size        = 15
    extra_user_data        = ""
    update_default_version = true
  }
}

variable "asg" {
  type = object({
    desired_capacity = number
    max_size         = number
    min_size         = number
  })
  description = "ASG에서 인스턴스의 최대, 최소, 희망 크기를 정한다."
  default = {
    desired_capacity = 1
    max_size         = 2
    min_size         = 1
  }
}

variable "alb_deletion_protection" {
  type        = bool
  description = "참이면 ALB를 바로 삭제할 수 없고, 콘솔이나 CLI에서 종료 보호 기능을 disable한 후에 제거 가능하다."
  default     = false
}

variable "ecr" {
  type = object({
    registry   = string
    repository = string
    tag        = string
  })
  description = "ECR 관련 정보"
  default = {
    registry   = ""
    repository = "nginx"
    tag        = "latest"
  }
}

variable "app" {
  type = object({
    port               = number
    allow_http_access  = bool
    allow_https_access = bool
    certificate_arn    = string
  })
  description = "어플리케이션 관련 정보"
  default = {
    port               = 80
    allow_http_access  = true
    allow_https_access = false
    certificate_arn    = ""
  }
}
