provider "aws" {
  region = "${var.region}"
}

locals {
  tags = {
    contact     = "${var.contact}"
    environment = "${var.environment}"
  }
}

module "jenkins_ha_agents" {
  source = "neiman-marcus/jenkins-ha-agents/aws"

  admin_password  = "${var.admin_password}"
  bastion_sg_name = "${var.bastion_sg_name}"
  domain_name     = "${var.domain_name}"

  private_subnet_name_az1 = "${var.private_subnet_name_az1}"
  private_subnet_name_az2 = "${var.private_subnet_name_az2}"
  public_subnet_name_az1  = "${var.public_subnet_name_az1}"
  public_subnet_name_az2  = "${var.public_subnet_name_az2}"

  r53_record = "${var.r53_record}"
  region     = "${var.region}"

  ssl_certificate = "${var.ssl_certificate}"
  ssm_parameter   = "${var.ssm_parameter}"

  tags     = "${local.tags}"
  vpc_name = "${var.vpc_name}"
}
