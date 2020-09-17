agent_max = 6

agent_lt_version = "$Latest"

agent_minx = 2

agent_volume_size = 16

ami_name = "amzn2-ami-hvm-2.0.*-x86_64-gp2"

ami_owner = "amazon"

api_ssm_parameter = "/api_key"

application = "jenkins"

auto_update_plugins_cron = "0 0 31 2 *"

bastion_sg_name = "bastion-sg"

cidr_ingress = ["0.0.0.0/0"]

contact = "admin@foo.io"

domain_name = "foo.io."

efs_mode = "bursting"

efs_provisioned_throughput = 3

environment = "prod"

executors = 4

instance_type = ["t3a.xlarge", "t3.xlarge", "t2.xlarge"]

jenkins_version = "2.249.1"

key_name = "foo"

master_lt_version = "$Latest"

password_ssm_parameter = "/admin_password"

private_subnet_name = "private-subnet-*"

public_subnet_name = "public-subnet-*"

r53_record = "jenkins.foo.io"

region = "us-east-1"

retention_in_days = 90

scale_down_number = -1

scale_up_number = 1

ssl_certificate = "*.foo.io"

ssm_parameter = "/jenkins/foo"

swarm_version = "3.23"

vpc_name = "prod-vpc"
