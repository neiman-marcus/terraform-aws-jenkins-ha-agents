# Full Jenkins-HA-Agents Example with Custom Userdata and Plugins.

Configuration in the directory provides the entire jenkins-ha-agents solution with every variable to be defined locally.

## Usage

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan -var admin_password=foo
$ terraform apply -var admin_password=foo
```

Note that this example may create resources which cost money. Run `terraform destroy` when you don't need these resources.