agent_max = 6

agent_minx = 2

ami_name = "amzn2-ami-hvm-2.0.*-x86_64-gp2"

ami_owner = "amazon"

api_ssm_parameter = "/api_key"

application = "jenkins"

auto_update_plugins_cron = "0 0 31 2 *"

bastion_sg_name = "bastion-sg"

cidr_ingress = ["0.0.0.0/0"]

contact = "admin@foo.io"

domain_name = "foo.io."

environment = "prod"

executors = 4

instance_type = "t2.large"

jenkins_version = "2.176.3"

password_ssm_parameter = "/admin_password"

private_subnet_name = "private-subnet-*"

public_subnet_name = "public-subnet-*"

r53_record = "jenkins.foo.io"

region = "us-east-1"

spot_price = "0.0928"

ssl_certificate = "*.foo.io"

ssm_parameter = "/jenkins/foo"

swarm_version = "3.17"

vpc_name = "prod-vpc"
