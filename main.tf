terraform {
  required_version = ">= 0.12"

  required_providers {
    aws      = "2.25.0"
    template = "2.1.2"
  }
}

data "aws_caller_identity" "current" {}

data "aws_security_group" "bastion_sg" {
  vpc_id = data.aws_vpc.vpc.id

  filter {
    name   = "group-name"
    values = [var.bastion_sg_name]
  }
}

data "aws_ami" "amzn2_ami" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name]
  }
}

data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.vpc.id

  tags = {
    Name = var.private_subnet_name
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.vpc.id

  tags = {
    Name = var.public_subnet_name
  }
}

data "aws_acm_certificate" "certificate" {
  domain   = var.ssl_certificate
  statuses = ["ISSUED"]
}

data "aws_route53_zone" "r53_zone" {
  name = var.domain_name
}

data "aws_iam_policy" "amazon_ec2_role_for_ssm" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_lb" "lb" {
  idle_timeout               = 60
  internal                   = false
  name                       = "${var.application}-lb"
  security_groups            = [aws_security_group.lb_sg.id]
  subnets                    = data.aws_subnet_ids.public.ids
  enable_deletion_protection = false

  tags = merge(
    var.tags,
    {
      "Name" = "${var.application}-lb"
    },
  )
}

resource "aws_security_group" "lb_sg" {
  name        = "${var.application}-lb-sg"
  description = "${var.application}-lb-sg"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.cidr_ingress
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.application}-lb-sg"
    },
  )
}

resource "aws_route53_record" "r53_record" {
  zone_id = data.aws_route53_zone.r53_zone.zone_id
  name    = var.r53_record
  type    = "A"

  alias {
    name                   = "dualstack.${aws_lb.lb.dns_name}"
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = false
  }
}

resource "aws_cloudwatch_metric_alarm" "available_executors_low" {
  alarm_name          = "${var.application}-available-executors-low"
  alarm_description   = "Alarm if the number of available executors are two low."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "AvailableExecutors"
  namespace           = "JenkinsBuildActiveQueue"
  period              = 30
  statistic           = "Minimum"
  threshold           = var.agent_min * var.executors / 2

  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.agent_asg.name
  }

  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.agent_scale_up_policy.arn]
}

resource "aws_cloudwatch_metric_alarm" "idle_executors_high" {
  alarm_name          = "${var.application}-idle-executors-high"
  alarm_description   = "Alarm if too many executors exist."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 10
  metric_name         = "IdleExecutors"
  namespace           = "JenkinsBuildActiveQueue"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0

  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.agent_asg.name
  }

  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.agent_scale_down_policy.arn]
}

resource "aws_cloudwatch_metric_alarm" "agent_cpu_alarm" {
  alarm_name          = "${var.application}-agent-cpu-alarm"
  alarm_description   = "Alarm if agent CPU is too high."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 50

  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.agent_asg.name
  }

  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.agent_scale_up_policy.arn]
}

resource "aws_autoscaling_group" "agent_asg" {
  depends_on = [aws_autoscaling_group.master_asg]

  max_size = var.agent_max
  min_size = var.agent_min

  health_check_grace_period = 300
  health_check_type         = "EC2"

  launch_configuration = aws_launch_configuration.agent_lc.name
  name_prefix          = "${var.application}-agent-"

  vpc_zone_identifier = data.aws_subnet_ids.private.ids

  tag {
    key                 = "Name"
    value               = "${var.application}-agent"
    propagate_at_launch = true
  }

  tag {
    key                 = "Launch Configuration"
    value               = aws_launch_configuration.agent_lc.name
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "agent_lc" {
  name_prefix   = "${var.application}-agent-"
  image_id      = data.aws_ami.amzn2_ami.id
  instance_type = var.instance_type

  spot_price = var.spot_price[var.instance_type]

  iam_instance_profile = aws_iam_instance_profile.agent_ip.name
  security_groups      = [aws_security_group.agent_sg.id]

  user_data = data.template_cloudinit_config.agent_init.rendered

  enable_monitoring = true
  ebs_optimized     = false

  root_block_device {
    volume_type           = "gp2"
    volume_size           = var.agent_volume_size
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "agent_sg" {
  name        = "${var.application}-agent-sg"
  description = "${var.application}-agent-sg"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [data.aws_security_group.bastion_sg.id]
    self            = false
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.application}-agent-sg"
    },
  )
}

resource "aws_iam_instance_profile" "agent_ip" {
  name = "${var.application}-agent-ip"
  path = "/"
  role = aws_iam_role.agent_iam_role.name
}

resource "aws_iam_role" "agent_iam_role" {
  name = "${var.application}-agent-iam-role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF


  tags = merge(
    var.tags,
    {
      "Name" = "${var.application}-agent-iam-role"
    },
  )
}

resource "aws_iam_role_policy" "agent_inline_policy" {
  name = "${var.application}-agent-inline-policy"
  role = aws_iam_role.agent_iam_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "autoscaling:DescribeAutoScalingGroups"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "${aws_cloudwatch_log_group.agent_logs.arn}"
    },
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": "ssm:GetParameter",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_parameter}${var.api_ssm_parameter}"
      ]
    },
    {
      "Action": "ec2:TerminateInstances",
      "Effect": "Allow",
      "Resource":[
        "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*"
      ],
      "Condition":{
        "StringEquals":{
            "ec2:ResourceTag/Name":"${var.application}-agent"
        }
      }
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "agent_policy_attachment" {
  role       = aws_iam_role.agent_iam_role.name
  policy_arn = data.aws_iam_policy.amazon_ec2_role_for_ssm.arn
}

resource "aws_cloudwatch_log_group" "agent_logs" {
  name = "${var.application}-agent-logs"

  tags = merge(
    var.tags,
    {
      "Name" = "${var.application}-agent-logs"
    },
  )
}

data "template_cloudinit_config" "agent_init" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "agent.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.agent_write_files.rendered
  }

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.agent_runcmd.rendered
  }

  part {
    content_type = "text/cloud-config"
    content      = var.extra_agent_userdata
    merge_type   = var.extra_agent_userdata_merge
  }

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.agent_end.rendered
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}

data "template_file" "agent_write_files" {
  template = file("${path.module}/init/agent-write-files.cfg")

  vars = {
    agent_logs    = aws_cloudwatch_log_group.agent_logs.name
    aws_region    = var.region
    executors     = var.executors
    swarm_version = var.swarm_version
  }
}

data "template_file" "agent_runcmd" {
  template = file("${path.module}/init/agent-runcmd.cfg")

  vars = {
    api_ssm_parameter = "${var.ssm_parameter}${var.api_ssm_parameter}"
    aws_region        = var.region
    master_asg        = aws_autoscaling_group.master_asg.name
    swarm_version     = var.swarm_version
  }
}

data "template_file" "agent_end" {
  template = file("${path.module}/init/agent-end.cfg")
}

resource "aws_autoscaling_policy" "agent_scale_up_policy" {
  name                   = "${var.application}-agent-up-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 150
  autoscaling_group_name = aws_autoscaling_group.agent_asg.name
}

resource "aws_autoscaling_policy" "agent_scale_down_policy" {
  name                   = "${var.application}-agent-down-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 180
  autoscaling_group_name = aws_autoscaling_group.agent_asg.name
}

resource "aws_autoscaling_group" "master_asg" {
  depends_on = [
    aws_efs_mount_target.mount_targets
  ]

  max_size = 1
  min_size = 1

  health_check_grace_period = 1200
  health_check_type         = "ELB"

  launch_configuration = aws_launch_configuration.master_lc.name
  name_prefix          = "${var.application}-master-"


  vpc_zone_identifier = data.aws_subnet_ids.private.ids

  target_group_arns = [aws_lb_target_group.master_tg.arn]

  tag {
    key                 = "Name"
    value               = "${var.application}-master"
    propagate_at_launch = true
  }

  tag {
    key                 = "Launch Configuration"
    value               = aws_launch_configuration.master_lc.name
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "master_lc" {
  name_prefix   = "${var.application}-master-"
  image_id      = data.aws_ami.amzn2_ami.id
  instance_type = var.instance_type

  iam_instance_profile = aws_iam_instance_profile.master_ip.name
  security_groups      = [aws_security_group.master_sg.id]

  user_data = data.template_cloudinit_config.master_init.rendered

  enable_monitoring = true
  ebs_optimized     = false

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 25
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "master_sg" {
  name        = "${var.application}-master-sg"
  description = "${var.application}-master-sg"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id, aws_security_group.agent_sg.id]
    self            = false
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [data.aws_security_group.bastion_sg.id]
    self            = false
  }

  ingress {
    from_port       = 49817
    to_port         = 49817
    protocol        = "tcp"
    security_groups = [aws_security_group.agent_sg.id]
    self            = false
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.application}-master-sg"
    },
  )
}

resource "aws_iam_instance_profile" "master_ip" {
  name = "${var.application}-master-ip"
  path = "/"
  role = aws_iam_role.master_iam_role.name
}

resource "aws_iam_role" "master_iam_role" {
  name = "${var.application}-master-iam-role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF


  tags = merge(
    var.tags,
    {
      "Name" = "${var.application}-master-iam-role"
    },
  )
}

resource "aws_iam_role_policy" "master_inline_policy" {
  name = "${var.application}-master-inline-policy"
  role = aws_iam_role.master_iam_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:PutMetricData"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "ec2:DescribeInstances",
        "autoscaling:DescribeAutoScalingGroups"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "${aws_cloudwatch_log_group.master_logs.arn}"
    },
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": "ssm:PutParameter",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_parameter}${var.api_ssm_parameter}"
      ]
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "master_policy_attachment" {
  role       = aws_iam_role.master_iam_role.name
  policy_arn = data.aws_iam_policy.amazon_ec2_role_for_ssm.arn
}

resource "aws_cloudwatch_log_group" "master_logs" {
  name = "${var.application}-master-logs"

  tags = merge(
    var.tags,
    {
      "Name" = "${var.application}-master-logs"
    },
  )
}

data "template_cloudinit_config" "master_init" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "master.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.master_write_files.rendered
  }

  part {
    content_type = "text/cloud-config"
    content      = var.custom_plugins
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.master_runcmd.rendered
  }

  part {
    content_type = "text/cloud-config"
    content      = var.extra_master_userdata
    merge_type   = var.extra_master_userdata_merge
  }

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.master_end.rendered
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }
}

data "template_file" "master_write_files" {
  template = file("${path.module}/init/master-write-files.cfg")

  vars = {
    admin_password           = var.admin_password
    api_ssm_parameter        = "${var.ssm_parameter}${var.api_ssm_parameter}"
    application              = var.application
    auto_update_plugins_cron = var.auto_update_plugins_cron
    aws_region               = var.region
    executors_min            = var.agent_min * var.executors
    master_logs              = aws_cloudwatch_log_group.master_logs.name
  }
}

data "template_file" "master_runcmd" {
  template = file("${path.module}/init/master-runcmd.cfg")

  vars = {
    admin_password  = var.admin_password
    aws_region      = var.region
    jenkins_version = var.jenkins_version
    master_storage  = aws_efs_file_system.master_efs.id
  }
}

data "template_file" "master_end" {
  template = file("${path.module}/init/master-end.cfg")
}

resource "aws_efs_file_system" "master_efs" {
  creation_token   = "${var.application}-master-efs"
  encrypted        = true
  performance_mode = "generalPurpose"

  throughput_mode                 = var.efs_mode
  provisioned_throughput_in_mibps = var.efs_mode == "provisioned" ? var.efs_provisioned_throughput : null

  tags = merge(
    var.tags,
    {
      "Name" = "${var.application}-master-efs"
    },
  )
}

resource "aws_efs_mount_target" "mount_targets" {
  for_each = toset(data.aws_subnet_ids.private.ids)

  file_system_id  = aws_efs_file_system.master_efs.id
  subnet_id       = each.key
  security_groups = [aws_security_group.master_storage_sg.id]
}

resource "aws_security_group" "master_storage_sg" {
  name        = "${var.application}-master-storage-sg"
  description = "${var.application}-master-storage-sg"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.master_sg.id]
    self            = false
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.application}-master-storage-sg"
    },
  )
}

resource "aws_lb_target_group" "master_tg" {
  name = "${var.application}-master-tg"

  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.vpc.id
  deregistration_delay = 30

  health_check {
    port                = "traffic-port"
    path                = "/login"
    timeout             = 25
    healthy_threshold   = 2
    unhealthy_threshold = 4
    matcher             = "200-299"
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.application}-master-tg"
    },
  )
}

resource "aws_lb_listener" "master_lb_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = data.aws_acm_certificate.certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.master_tg.arn
  }
}

resource "aws_ssm_parameter" "admin_password" {
  name        = "${var.ssm_parameter}${var.password_ssm_parameter}"
  description = "${var.application}-admin-password"
  type        = "SecureString"
  value       = var.admin_password
  overwrite   = true
}

