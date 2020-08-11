![logo](https://github.com/neiman-marcus/terraform-aws-jenkins-ha-agents/raw/master/images/logo.png 'Neiman Marcus')

# terraform-aws-jenkins-ha-agents

[![verson](https://img.shields.io/github/v/release/neiman-marcus/terraform-aws-jenkins-ha-agents)](https://registry.terraform.io/modules/neiman-marcus/jenkins-ha-agents/aws) [![build](https://img.shields.io/github/workflow/status/neiman-marcus/terraform-aws-jenkins-ha-agents/tf-lint)](https://github.com/neiman-marcus/terraform-aws-jenkins-ha-agents/actions?query=workflow%3Atf-lint) [![license](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://github.com/neiman-marcus/terraform-aws-jenkins-ha-agents/blob/master/LICENSE) [![pr](https://img.shields.io/badge/PRs-welcome-blue.svg)](https://github.com/neiman-marcus/terraform-aws-jenkins-ha-agents/blob/master/CONTRIBUTING.md)

A module for deploying Jenkins in a highly available and highly scalable manner.

Related blog post can be found on the [Neiman Marcus Medium page](https://medium.com/neiman-marcus-tech/developing-a-terraform-jenkins-module-dccfd4381355?source=friends_link&sk=9aa056d2da2d98ac33c7e06ecd22563f).

## Features

- Highly available architecture with agents and master in an autoscaling group
- EFS volume used for master node persistence
- Jenkins versions incremented through variable
- Complete Infrastructure as code deployment, no plugin configuration required
- Spot instance pricing for agents
- Custom user data available
- Auto update plugins

## Terraform & Module Version

**Terraform 0.13** - Pin module version to `~> v3.0`. Submit pull-requests to `master` branch.

**Terraform 0.12** - Pin module version to `~> v2.0`. Submit pull-requests to `terraform12` branch. Only bug fixs will be accepted. All new developement will be on Terraform 0.13.

**Terraform 0.11** - Deprecated in this module.

## Usage

To be used with a local map of tags.

### Minimum Configuration

```TERRAFORM
module "jenkins_ha_agents" {
  source  = "neiman-marcus/jenkins-ha-agents/aws"
  version = "x.x.x"

  admin_password  = "foo"
  bastion_sg_name = "bastion-sg"
  domain_name     = "foo.io."

  private_subnet_name = "private-subnet-*"
  public_subnet_name  = "public-subnet-*"

  r53_record = "jenkins.foo.io"
  region     = "us-west-2"

  ssl_certificate = "*.foo.io"
  ssm_parameter   = "/jenkins/foo"

  tags     = local.tags
  vpc_name = "prod-vpc"
}
```

### Full Configuration with Custom Userdata and Plugins

#### main.tf

```TERRAFORM
module "jenkins_ha_agents" {
  source  = "neiman-marcus/jenkins-ha-agents/aws"
  version = "x.x.x"

  admin_password    = "foo"
  agent_max         = 6
  agent_min         = 2
  agent_volume_size = 16

  ami_name          = "amzn2-ami-hvm-2.0.*-x86_64-gp2"
  ami_owner         = "amazon"
  api_ssm_parameter = "/api_key"

  auto_update_plugins_cron = "0 0 31 2 *"

  efs_mode                   = "provisioned"
  efs_provisioned_throughput = 3

  application     = "jenkins"
  bastion_sg_name = "bastion-sg"
  domain_name     = "foo.io."

  agent_lt_version  = "$Latest"
  master_lt_version = "$Latest"

  key_name          = "foo"
  scale_down_number = -1
  scale_up_number   = 1

  custom_plugins              = data.template_file.custom_plugins.rendered
  extra_agent_userdata        = data.template_file.extra_agent_userdata.rendered
  extra_agent_userdata_merge  = "list(append)+dict(recurse_array)+str()"
  extra_master_userdata       = data.template_file.extra_master_userdata.rendered
  extra_master_userdata_merge = "list(append)+dict(recurse_array)+str()"

  retention_in_days = 90

  executors              = 4
  instance_type          = ["t3a.xlarge", "t3.xlarge", "t2.xlarge"]
  jenkins_version        = "2.235.2"
  password_ssm_parameter = "/admin_password"

  cidr_ingress        = ["0.0.0.0/0"]
  private_subnet_name = "private-subnet-*"
  public_subnet_name  = "public-subnet-*"

  r53_record      = "jenkins.foo.io"
  region          = "us-west-2"
  ssl_certificate = "*.foo.io"

  ssm_parameter = "/jenkins/foo"
  swarm_version = "3.22"
  tags          = local.tags
  vpc_name      = "prod-vpc"
}

data "template_file" "custom_plugins" {
  template = file("init/custom_plugins.cfg")
}

data "template_file" "extra_agent_userdata" {
  template = file("init/extra_agent_userdata.cfg")

  vars {
    foo = "bar"
  }
}

data "template_file" "extra_master_userdata" {
  template = file("init/extra_master_userdata.cfg")

  vars {
    foo = "bar"
  }
}
```

#### init/custom_plugins.cfg

```YAML
---
#cloud-config

write_files:
  - path: /root/custom_plugins.txt
    content: |
      cloudbees-folder
    permissions: "000400"
    owner: root
    group: root
```

#### init/extra_agent_userdata.cfg

```YAML
---
runcmd:
  - echo 'foo = ${foo}'
```

#### init/extra_master_userdata.cfg

```YAML
---
runcmd:
  - echo 'foo = ${foo}'
```

## Examples

- [Full Jenkins-HA-Agents Example](https://github.com/neiman-marcus/terraform-aws-jenkins-ha-agents/tree/master/examples/full)
- [Minimum Jenkins-HA-Agents Example](https://github.com/neiman-marcus/terraform-aws-jenkins-ha-agents/tree/master/examples/minimum)

## Inputs

| Name                        | Description                                                                                                                                                                |  Type  |                   Default                    | Required |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----: | :------------------------------------------: | :------: |
| admin_password              | The master admin password. Used to bootstrap and login to the master. Also pushed to ssm parameter store for posterity.                                                    | string |                    `N/A`                     |   yes    |
| agent_lt_version            | The version of the agent launch template to use. Only use if you need to programatically select an older version of the launch template. Not recommended to change.        | string |                  `$Latest`                   |    no    |
| agent_max                   | The maximum number of agents to run in the agent ASG.                                                                                                                      |  int   |                     `6`                      |    no    |
| agent_min                   | The minimum number of agents to run in the agent ASG.                                                                                                                      |  int   |                     `2`                      |    no    |
| agent_volume_size           | The size of the agent volume.                                                                                                                                              |  int   |                     `16`                     |    no    |
| ami_name                    | The name of the amzn2 ami. Used for searching for AMI id.                                                                                                                  | string |       `amzn2-ami-hvm-2.0.*-x86_64-gp2`       |    no    |
| ami_owner                   | The owner of the amzn2 ami.                                                                                                                                                | string |                   `amazon`                   |    no    |
| api_ssm_parameter           | The path value of the API key, stored in ssm parameter store.                                                                                                              | string |                  `/api_key`                  |    no    |
| application                 | The application name, to be interpolated into many resources and tags. Unique to this project.                                                                             | string |                  `jenkins`                   |    no    |
| auto_update_plugins_cron    | Cron to set to auto update plugins. The default is set to February 31st, disabling this functionality. Overwrite this variable to have plugins auto update.                | string |                 `0 0 31 2 *`                 |    no    |
| bastion_sg_name             | The bastion security group name to allow to ssh to the master/agents.                                                                                                      | string |                    `N/A`                     |   yes    |
| cidr_ingress                | IP address cidr ranges allowed access to the LB.                                                                                                                           | string |               `["0.0.0.0/0"]`                |    no    |
| custom_plugins              | Custom plugins to install when bootstrapping. Created from a template outside of the module.                                                                               | string |                   `empty`                    |    no    |
| domain_name                 | The root domain name used to lookup the route53 zone information.                                                                                                          | string |                    `N/A`                     |   yes    |
| efs_mode                    | The EFS throughput mode. Options are bursting and provisioned. To set the provisioned throughput in mibps, configure `efs_provisioned_throughput` variable.                | string |                  `bursting`                  |    no    |
| efs_provisioned_throughput  | The EFS provisioned throughput in mibps. Ignored if EFS throughput mode is set to bursting.                                                                                |  int   |                     `3`                      |    no    |
| executors                   | The number of executors to assign to each agent. Must be an even number, divisible by two.                                                                                 |  int   |                     `4`                      |    no    |
| extra_agent_userdata        | Extra agent user-data to add to the default built-in. Created from a template outside of the module.                                                                       | string |                   `empty`                    |    no    |
| extra_agent_userdata_merge  | Control how cloud-init merges custom agent user-data sections.                                                                                                             | string | `list(append) + dict(recurse_array) + str()` |    no    |
| extra_master_userdata       | Extra master user-data to add to the default built-in. Created from a template outside of the module.                                                                      | string |                   `empty`                    |    no    |
| extra_master_userdata_merge | Control how cloud-init merges custom master user-data sections.                                                                                                            | string | `list(append) + dict(recurse_array) + str()` |    no    |
| instance_type               | The type of instances to use for both ASG's. The first value in the list will be set as the master instance.                                                               |  list  |      `t3a.xlarge, t3.xlarge, t2.xlarge`      |    no    |
| jenkins_version             | The version number of Jenkins to use on the master. Change this value when a new version comes out, and it will update the launch configuration and the autoscaling group. | string |                  `2.235.2`                   |    no    |
| key_name                    | SSH Key to launch instances.                                                                                                                                               | string |                    `null`                    |    no    |
| master_lt_version           | The version of the master launch template to use. Only use if you need to programatically select an older version of the launch template. Not recommended to change.       | string |                  `$Latest`                   |    no    |
| password_ssm_parameter      | The path value of the master admin passowrd, stored in ssm parameter store.                                                                                                | string |              `/admin_password`               |    no    |
| private_subnet_name         | The name prefix of the private subnets to pull in as a data source.                                                                                                        | string |                    `N/A`                     |   yes    |
| public_subnet_name          | The name prefix of the public subnets to pull in as a data source.                                                                                                         | string |                    `N/A`                     |   yes    |
| r53_record                  | The FQDN for the route 53 record.                                                                                                                                          | string |                    `N/A`                     |   yes    |
| region                      | The AWS region to deploy the infrastructure too.                                                                                                                           | string |                    `N/A`                     |   yes    |
| retention_in_days           | How many days to retain cloudwatch logs.                                                                                                                                   |  int   |                     `90`                     |    no    |
| scale_down_number           | Number of agents to destroy when scaling down.                                                                                                                             |  int   |                     `-1`                     |    no    |
| scale_up_number             | Number of agents to create when scaling up.                                                                                                                                |  int   |                     `1`                      |    no    |
| ssl_certificate             | The name of the SSL certificate to use on the load balancer.                                                                                                               | string |                    `N/A`                     |   yes    |
| ssm_parameter               | The full ssm parameter path that will house the api key and master admin password. Also used to grant IAM access to this resource.                                         | string |                    `N/A`                     |   yes    |
| swarm_version               | The version of swarm plugin to install on the agents. Update by updating this value.                                                                                       |  int   |                    `3.22`                    |    no    |
| tags                        | tags to define locally, and interpolate into the tags in this module.                                                                                                      | string |                    `N/A`                     |   yes    |
| vpc_name                    | The name of the VPC the infrastructure will be deployed to.                                                                                                                | string |                    `N/A`                     |   yes    |

## Outputs

| Name            | Description                                                               |
| --------------- | ------------------------------------------------------------------------- |
| agent_asg_name  | The name of the agent asg. Use for adding to addition outside resources.  |
| agent_iam_role  | The agent IAM role attributes. Use for attaching additional iam policies. |
| master_asg_name | The name of the master asg. Use for adding to addition outside resources. |
| master_iam_role | The master IAM role name. Use for attaching additional iam policies.      |
| r53_record_fqdn | The fqdn of the route 53 record.                                          |

## Known Issues/Limitations

N/A

## Notes

- It can take a decent amount of time for initial master bootstrap (approx 11 minutes on t2.micro).
  - This is normal, and sped up by higher instance types.
  - After the master is built and EFS is populated with Jenkins installation configuration, master boot times come down considerably.
- During initial bootstrapping the master reboots several times.
- You should not need to change the admin password in the Jenkins wizard.
  - This is done through bootstrapping.
  - If you run through the wizard and it asks you to change the admin password, wait a short time and reload the page.
  - Do not click 'Continue as admin' on the password reset page, just wait and reload.

## Breaking Changes

### v2.5.0

- Giving custom names to ASG's has been removed. This should only impact external resources created outside of the module.
- ASG's no longer rehydrate with launch template/configuration revisions. You will need to manaully rehydrate your ASG's with new instances.
- Spot pricing variable has been removed as the agent ASG was moved to launch template, and does not require this parameter (defaults to on-demand max price).
- Instance type variable has been changed to a list to accomodate multiple launch template overrides. If you use a non-default value, you will have to change your variable to a list.

### v2.1.0

- This version of the module pulls all public and private subnets using a wildcard.
  - This allows for more than two hardcoded subnets.
  - You may have to destroy several resources and create them again, including mount targets.
  - As long as you do not delete your EFS volume, there should be no data loss.
- Cidr blocks have been consolidated to reduce redundant configuration.

## How it works

The architecture, on the surface, is simple, but has a lot of things going on under the hood. Similar to a basic web-application architecture, a load balancer sits in front of the master auto scaling group, which connects directly to the agent autoscaling group.

### Master Node Details

The Master node sits in an autoscaling group, using the Amazon Linux 2 AMI. The autoscaling group is set to a minimum and maximum of one instance. The autoscaling group does not scale out or in. It can be in one of two availability zones. It is fronted by an ELB which can control the autoscaling group based on a health check. If port 8080 is not functioning properly, the ELB will terminate the instance.

The name of the master autoscaling group is identical to the master launch configuration. This is intentional. If the launch configuration is updated, the master autoscaling group will be recreated with the new launch configuration.

Data are persisted through an EFS volume, with a mount target in each availability zone.

During initial launch, the master will generate an API key and publish it to SSM Parameter store.

### Agent Nodes Details

Agent nodes are also set in an autoscaling group, using the Amazon Linux 2 AMI, set in the same availability zones.

Agents connect to the master node through the Jenkins SWARM plugin. The agents are smart enough to get the master's IP address using the AWS CLI and API key from the parameter store. Agents launch, configure themselves, and connect to the master. If agents cannot connect or get disconnected, the agent will self-terminate, causing the autoscaling group to create a new instance. This helps in the case that the agents launch, and the master has not yet published the API key to the parameter store. After it is published, the agents and master will sync up. If the master is terminated, the agents will automatically terminate.

Agents are spot instances, keeping cost down.

### Agent Scaling Details

Agents scale based on CPU, and on the Jenkins build queue. The master node will poll itself to see how many executors are busy and send a CloudWatch metric alarm. If the number of executors available is less than half, then the autoscaling group will scale up. If executors are idle, then the agents will scale down. This is configured in the cloud-init user data.

### Updating Jenkins/SWARM Version

To update Jenkins or the SWARM plugin, update the variable in the terraform.tfvars files and redeploy the stack. The master will rebuild with the new version of Jenkins, maintaining configuration on the EFS volume. The agents will redeploy with the new version of SWARM.

### Auto Updating Plugins

The master has the ability to check for plugin updates, and automatically install them. By default, this feature is disabled. To enable it, set the `auto_update_plugins_cron` argument. Finally, it saves the list of plugins, located in `/var/lib/jenkins/plugin-updates/archive` for further review. You are encouraged to use something like AWS Backup to take daily backups of your EFS volume, and set the cron to a time during a maintenance window.

## Diagram

![Diagram](https://github.com/neiman-marcus/terraform-aws-jenkins-ha-agents/raw/master/images/diagram.png 'Diagram')

## FAQ

### Why not use ECS or Fargate?

ECS still requires managing instances with an autoscaling group, in addition to the ECS containers and configuration. Just using autoscaling groups is less management overhead.

Fargate cannot be used with the master node as it cannot currently mount EFS volumes. It is also more costly than spot pricing for the agents.

### Why not use a plugin to create agents?

The goal is to completely define the deployment with code. If a plugin is used and configured for agent deployment, defining the solution as code would be more challenging. With the SWARM plugin, and the current configuration, the infrastructure deploys instances, and the instance user data connects. The master is only used for scaling in and out based on executor load.

## Possible Improvements

Below are a list of possible improvements identified. Please feel free to develope and test. These may or may not be implemented.

- Fargate agents instead of instances
- Fargate master with EFS mount
- EFS mount helper
- Add instance protection to agents actively executing jobs
- Add signaling to the master and agent bootstraping process
- IAM policy document resources instead of plain json
- ~~Add the ability to include custom iam policy details from variable inputs~~ / Added in v2.5.0
- ~~Move towards launch templates instead of launch configuration~~ / Added in v2.5.0

## Authors

- [**Clay Danford**](mailto:clay_danford@neimanmarcus.com) - Project creation and development.

## Conduct / Contributing / License

- Refer to our contribution guidelines to contribute to this project. See [CONTRIBUTING.md](https://github.com/neiman-marcus/terraform-aws-jenkins-ha-agents/tree/master/CONTRIBUTING.md).
- All contributions must follow our code of conduct. See [CONDUCT.md](https://github.com/neiman-marcus/terraform-aws-jenkins-ha-agents/tree/master/CONDUCT.md).
- This project is licensed under the Apache 2.0 license. See [LICENSE](https://github.com/neiman-marcus/terraform-aws-jenkins-ha-agents/tree/master/LICENSE).

## Acknowledgments

- [**Cloudonaut.io Template**](https://github.com/widdix/aws-cf-templates/blob/master/jenkins/jenkins2-ha-agents.yaml) - Original cloudformation template, this project is based on.
