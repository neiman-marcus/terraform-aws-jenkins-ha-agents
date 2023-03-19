variable "admin_password" {
  description = "The master admin password. Used to bootstrap and login to the master. Also pushed to ssm parameter store for posterity."
  type        = string
}

variable "agent_lt_version" {
  description = "The version of the agent launch template to use. Only use if you need to programatically select an older version of the launch template. Not recommended to change."
  type        = string
  default     = "$Latest"
}

variable "agent_max" {
  description = "The maximum number of agents to run in the agent ASG."
  type        = number
  default     = 6
}

variable "agent_min" {
  description = "The minimum number of agents to run in the agent ASG."
  type        = number
  default     = 2
}

variable "agent_volume_size" {
  description = "The size of the agent volume."
  type        = number
  default     = 16
}

variable "ami_name" {
  description = "The name of the amzn2 ami. Used for searching for AMI id."
  type        = string
  default     = "amzn2-ami-hvm-2.0.*-x86_64-gp2"
}

variable "ami_owner" {
  description = "The owner of the amzn2 ami."
  type        = string
  default     = "amazon"
}

variable "api_ssm_parameter" {
  description = "The path value of the API key, stored in ssm parameter store."
  type        = string
  default     = "/api_key"
}

variable "application" {
  description = "The application name, to be interpolated into many resources and tags. Unique to this project."
  type        = string
  default     = "jenkins"
}

variable "auto_update_plugins_cron" {
  description = "Cron to set to auto update plugins. The default is set to February 31st, disabling this functionality. Overwrite this variable to have plugins auto update."
  type        = string
  default     = "0 0 31 2 *"
}

variable "bastion_sg_name" {
  description = "The bastion security group name to allow to ssh to the master/agents."
  type        = string
}

variable "cidr_ingress" {
  description = "IP address cidr ranges allowed access to the LB."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "contact" {
  description = "The email of the contact who owns or manages this infrastructure."
  type        = string
  default     = "admin@foo.io"
}

variable "domain_name" {
  description = "The root domain name used to lookup the route53 zone information."
  type        = string
}

variable "efs_mode" {
  description = "The EFS throughput mode. Options are bursting and provisioned. To set the provisioned throughput in mibps, configure efs_provisioned_throughput variable."
  type        = string
  default     = "bursting"
}

variable "efs_provisioned_throughput" {
  description = "The EFS provisioned throughput in mibps. Ignored if EFS throughput mode is set to bursting."
  type        = number
  default     = 3
}

variable "environment" {
  description = "The environment type, prod or nonprod."
  type        = string
  default     = "prod"
}

variable "executors" {
  description = "The number of executors to assign to each agent. Must be an even number, divisible by two."
  type        = number
  default     = 4
}

variable "instance_type_controller" {
  description = "The type of instances to use for controller autoscaling group (ASG)."
  type        = list(string)
  default     = ["t3a.xlarge"]
}

variable "instance_type_agents" {
  description = "The type of instances to use for agent's autoscaling group (ASG)"
  type        = list(string)
  default     = ["t3.xlarge", "t3a.xlarge", "t2.xlarge", "t2a.xlarge"]
}

variable "jenkins_version" {
  description = "The version number of Jenkins to use on the master. Change this value when a new version comes out, and it will update the launch configuration and the autoscaling group."
  type        = string
  default     = "2.249.1"
}

variable "key_name" {
  description = "SSH Key to launch instances."
  type        = string
  default     = null
}

variable "master_lt_version" {
  description = "The version of the master launch template to use. Only use if you need to programatically select an older version of the launch template. Not recommended to change."
  type        = string
  default     = "$Latest"
}

variable "password_ssm_parameter" {
  description = "The path value of the master admin passowrd, stored in ssm parameter store."
  type        = string
  default     = "/admin_password"
}

variable "private_subnet_name" {
  description = "The name prefix of the private subnets to pull in as a data source."
  type        = string
}

variable "public_subnet_name" {
  description = "The name prefix of the public subnets to pull in as a data source."
  type        = string
}

variable "r53_record" {
  description = "The FQDN for the route 53 record."
  type        = string
}

variable "region" {
  description = "The AWS region to deploy the infrastructure too."
  type        = string
}

variable "retention_in_days" {
  description = "How many days to retain cloudwatch logs."
  type        = number
  default     = 90
}

variable "scale_down_number" {
  description = "Number of agents to destroy when scaling down."
  type        = number
  default     = -1
}

variable "scale_up_number" {
  description = "Number of agents to create when scaling up."
  type        = number
  default     = 1
}

variable "ssl_certificate" {
  description = "The name of the SSL certificate to use on the load balancer."
  type        = string
}

variable "ssm_parameter" {
  description = "The full ssm parameter path that will house the api key and master admin password. Also used to grant IAM access to this resource."
  type        = string
}

variable "swarm_version" {
  description = "The version of swarm plugin to install on the agents. Update by updating this value."
  type        = string
  default     = "3.23"
}

variable "vpc_name" {
  description = "The name of the VPC the infrastructure will be deployed to."
  type        = string
}

variable "time_to_start" {
  description = "Set a timeout in seconds when systemctl will restart service due of inactivity, if instance became smaller than timeout has to be bigger. Default 90 seconds."
  type        = string
  default     = 90
}
