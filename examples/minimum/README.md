# Minimum Jenkins-HA-Agents Example

Configuration in the directory provides the entire jenkins-ha-agents solution with as many defaults used as possible.

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan -var admin_password=foo
$ terraform apply -var admin_password=foo
```

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these resources.