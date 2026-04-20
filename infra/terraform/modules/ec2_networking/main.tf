data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
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
  count             = (var.enabled && var.allow_http) ? 1 : 0
  type              = "ingress"
  security_group_id = aws_security_group.ec2[0].id
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = [var.http_cidr]
  description       = "Temporary app access on port 8080"
}

resource "aws_instance" "this" {
  count = var.enabled ? var.desired_count : 0

  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_ids[count.index % length(var.subnet_ids)]
  vpc_security_group_ids      = [aws_security_group.ec2[0].id]
  associate_public_ip_address = true

  tags = {
    Name        = "${var.name_prefix}-ec2-${count.index + 1}"
    Project     = "tasktracker"
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "Doug"
  }
}