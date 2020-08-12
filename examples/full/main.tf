provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 0.13"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.25"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.1"
    }
  }
}

locals {
  tags = {
    contact     = var.contact
    environment = var.environment
  }
}

module "jenkins_ha_agents" {
  source = "../../"

  admin_password    = var.admin_password
  agent_max         = var.agent_max
  agent_min         = var.agent_min
  agent_volume_size = var.agent_volume_size

  efs_mode                   = var.efs_mode
  efs_provisioned_throughput = var.efs_provisioned_throughput

  ami_name          = var.ami_name
  ami_owner         = var.ami_owner
  api_ssm_parameter = var.api_ssm_parameter

  application     = var.application
  bastion_sg_name = var.bastion_sg_name
  domain_name     = var.domain_name

  key_name          = var.key_name
  scale_down_number = var.scale_down_number
  scale_up_number   = var.scale_up_number

  auto_update_plugins_cron = var.auto_update_plugins_cron

  custom_plugins              = data.template_file.custom_plugins.rendered
  extra_agent_userdata        = data.template_file.extra_agent_userdata.rendered
  extra_agent_userdata_merge  = "list(append)+dict(recurse_array)+str()"
  extra_master_userdata       = data.template_file.extra_master_userdata.rendered
  extra_master_userdata_merge = "list(append)+dict(recurse_array)+str()"

  retention_in_days = var.retention_in_days

  executors              = var.executors
  instance_type          = var.instance_type
  jenkins_version        = var.jenkins_version
  password_ssm_parameter = var.password_ssm_parameter

  cidr_ingress        = var.cidr_ingress
  private_subnet_name = var.private_subnet_name
  public_subnet_name  = var.public_subnet_name

  r53_record      = var.r53_record
  region          = var.region
  ssl_certificate = var.ssl_certificate

  ssm_parameter = var.ssm_parameter
  swarm_version = var.swarm_version
  tags          = local.tags
  vpc_name      = var.vpc_name
}

data "template_file" "extra_agent_userdata" {
  template = file("init/extra-agent-userdata.cfg")

  vars = {
    foo = "bar"
  }
}

data "template_file" "extra_master_userdata" {
  template = file("init/extra-master-userdata.cfg")

  vars = {
    foo = "bar"
  }
}

data "template_file" "custom_plugins" {
  template = file("init/custom_plugins.cfg")
}

