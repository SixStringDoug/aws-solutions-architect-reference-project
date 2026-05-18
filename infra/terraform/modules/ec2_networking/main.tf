data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "ec2" {
  count = var.enabled ? 1 : 0

  name              = "/${var.name_prefix}/ec2"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "/${var.name_prefix}/ec2"
    Project     = "tasktracker"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}

resource "aws_security_group" "ec2" {
  count  = var.enabled ? 1 : 0
  name   = "${var.name_prefix}-ec2-sg"
  vpc_id = var.vpc_id

  description = "EC2 networking-only SG (no app ports yet)"

  # Default: no inbound rules (use SSM later; SSH optional toggle below)

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name_prefix}-ec2-sg"
    Project     = "tasktracker"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}

resource "aws_security_group_rule" "ssh" {
  count             = (var.enabled && var.allow_ssh) ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.ec2[0].id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.ssh_cidr]
  description       = "Temporary SSH (only when allow_ssh=true)"
}

resource "aws_security_group_rule" "http_8080" {
  count             = (var.enabled && var.enable_alb) ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.ec2[0].id
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"

  source_security_group_id = aws_security_group.alb[0].id

  description = "Allow ALB to reach EC2 app on port 8080"
}

# ------------------------------------------------------------
# Application Load Balancer
# ------------------------------------------------------------

resource "aws_security_group" "alb" {
  count = (var.enabled && var.enable_alb) ? 1 : 0

  name        = "${var.name_prefix}-ec2-alb-sg"
  description = "Public ALB security group for EC2 application access"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound to EC2 targets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name_prefix}-ec2-alb-sg"
    Project     = "tasktracker"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}

resource "aws_lb" "ec2_app" {
  count = (var.enabled && var.enable_alb) ? 1 : 0

  name               = "${var.name_prefix}-ec2-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = var.subnet_ids

  tags = {
    Name        = "${var.name_prefix}-ec2-alb"
    Project     = "tasktracker"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}

resource "aws_lb_target_group" "ec2_app" {
  count = (var.enabled && var.enable_alb) ? 1 : 0

  name        = "${var.name_prefix}-ec2-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.name_prefix}-ec2-tg"
    Project     = "tasktracker"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}

resource "aws_lb_listener" "http" {
  count = (var.enabled && var.enable_alb) ? 1 : 0

  load_balancer_arn = aws_lb.ec2_app[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_app[0].arn
  }
}

resource "aws_iam_role" "ec2_app" {
  count = var.enabled ? 1 : 0

  name = "${var.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name        = "${var.name_prefix}-ec2-role"
    Project     = "tasktracker"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}

resource "aws_iam_role_policy" "ec2_app" {
  count = var.enabled ? 1 : 0

  name = "${var.name_prefix}-ec2-policy"
  role = aws_iam_role.ec2_app[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadAppJarFromS3"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::${var.artifact_bucket_name}/tasktracker.jar"
      },
      {
        Sid    = "ReadDbParametersFromSsm"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_parameter_paths.db_host}",
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_parameter_paths.db_port}",
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_parameter_paths.db_username}",
          "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_parameter_paths.db_password}"
        ]
      },
      {
        Sid    = "DecryptSecureStringParameters"
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService"    = "ssm.${data.aws_region.current.name}.amazonaws.com"
            "kms:CallerAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "WriteEc2LogsToCloudWatch"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.ec2[0].arn}:*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_app" {
  count = var.enabled ? 1 : 0

  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2_app[0].name
}

resource "aws_launch_template" "ec2_app" {
  count = var.enabled ? 1 : 0

  name_prefix   = "${var.name_prefix}-ec2-lt-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_app[0].name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2[0].id]
  }

  user_data = base64encode(var.user_data)

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "${var.name_prefix}-ec2-asg-instance"
      Project     = "tasktracker"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "Doug"
    }
  }

  tags = {
    Name        = "${var.name_prefix}-ec2-launch-template"
    Project     = "tasktracker"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}

resource "aws_autoscaling_group" "ec2_app" {
  count = var.enabled ? 1 : 0

  name                = "${var.name_prefix}-ec2-asg"
  desired_capacity    = var.desired_count
  min_size            = var.desired_count
  max_size            = var.desired_count
  vpc_zone_identifier = var.subnet_ids

  health_check_type         = var.enable_alb ? "ELB" : "EC2"
  health_check_grace_period = 180

  target_group_arns = var.enable_alb ? [aws_lb_target_group.ec2_app[0].arn] : []

  launch_template {
    id      = aws_launch_template.ec2_app[0].id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-ec2-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "tasktracker"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "terraform"
    propagate_at_launch = true
  }

  tag {
    key                 = "Owner"
    value               = "Doug"
    propagate_at_launch = true
  }

  depends_on = [
    aws_cloudwatch_log_group.ec2,
    aws_lb_listener.http
  ]
}

resource "aws_cloudwatch_metric_alarm" "ec2_asg_in_service_instances_low" {
  count = var.enabled ? 1 : 0

  alarm_name        = "${var.name_prefix}-ec2-asg-in-service-instances-low"
  alarm_description = "Alarm when the EC2 Auto Scaling Group has fewer in-service instances than desired"

  namespace           = "AWS/AutoScaling"
  metric_name         = "GroupInServiceInstances"
  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 2
  threshold           = var.desired_count
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ec2_app[0].name
  }

  tags = {
    Name        = "${var.name_prefix}-ec2-asg-in-service-instances-low"
    Project     = "tasktracker"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_alb_unhealthy_hosts" {
  count = (var.enabled && var.enable_alb) ? 1 : 0

  alarm_name          = "${var.name_prefix}-ec2-alb-unhealthy-hosts"
  alarm_description   = "Alarm when the EC2 ALB target group has unhealthy targets"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = aws_lb_target_group.ec2_app[0].arn_suffix
    LoadBalancer = aws_lb.ec2_app[0].arn_suffix
  }

  tags = {
    Name        = "${var.name_prefix}-ec2-alb-unhealthy-hosts"
    Project     = "tasktracker"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_alb_target_5xx" {
  count = (var.enabled && var.enable_alb) ? 1 : 0

  alarm_name          = "${var.name_prefix}-ec2-alb-target-5xx"
  alarm_description   = "Alarm when EC2 ALB targets return 5XX errors"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 2
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TargetGroup  = aws_lb_target_group.ec2_app[0].arn_suffix
    LoadBalancer = aws_lb.ec2_app[0].arn_suffix
  }

  tags = {
    Name        = "${var.name_prefix}-ec2-alb-target-5xx"
    Project     = "tasktracker"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}