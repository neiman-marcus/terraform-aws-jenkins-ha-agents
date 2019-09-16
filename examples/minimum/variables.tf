variable "admin_password" {
  description = "The master admin password. Used to bootstrap and login to the master. Also pushed to ssm parameter store for posterity."
}

variable "bastion_sg_name" {
  description = "The bastion security group name to allow to ssh to the master/agents."
}

variable "contact" {
  description = "The email of the contact who owns or manages this infrastructure."
  default     = "admin@foo.io"
}

variable "domain_name" {
  description = "The root domain name used to lookup the route53 zone information."
}

variable "environment" {
  description = "The environment type, prod or nonprod."
  default     = "prod"
}

variable "private_subnet_name" {
  description = "The name prefix of the private subnets to pull in as a data source."
}

variable "public_subnet_name" {
  description = "The name prefix of the public subnets to pull in as a data source."
}

variable "r53_record" {
  description = "The FQDN for the route 53 record."
}

variable "region" {
  description = "The AWS region to deploy the infrastructure too."
}

variable "ssl_certificate" {
  description = "The name of the SSL certificate to use on the load balancer."
}

variable "ssm_parameter" {
  description = "The full ssm parameter path that will house the api key and master admin password. Also used to grant IAM access to this resource."
}

variable "vpc_name" {
  description = "The name of the VPC the infrastructure will be deployed to."
}

