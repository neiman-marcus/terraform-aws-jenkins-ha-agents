variable "admin_password" {
  description = "The master admin password. Used to bootstrap and login to the master. Also pushed to ssm parameter store for posterity."
  type        = string
}

variable "bastion_sg_name" {
  description = "The bastion security group name to allow to ssh to the master/agents."
  type        = string
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

variable "environment" {
  description = "The environment type, prod or nonprod."
  type        = string
  default     = "prod"
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

variable "ssl_certificate" {
  description = "The name of the SSL certificate to use on the load balancer."
  type        = string
}

variable "ssm_parameter" {
  description = "The full ssm parameter path that will house the api key and master admin password. Also used to grant IAM access to this resource."
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC the infrastructure will be deployed to."
  type        = string
}

