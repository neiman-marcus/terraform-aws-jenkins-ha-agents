output "agent_asg_name" {
  description = "The name of the agent asg. Use for adding to addition outside resources."
  value       = aws_autoscaling_group.agent_asg.name
}

output "agent_iam_role" {
  description = "The agent IAM role attributes. Use for attaching additional iam policies."
  value       = aws_iam_role.agent_iam_role.name
}

output "master_asg_name" {
  description = "The name of the master asg. Use for adding to addition outside resources."
  value       = aws_autoscaling_group.master_asg.name
}

output "master_iam_role" {
  description = "The master IAM role name. Use for attaching additional iam policies."
  value       = aws_iam_role.master_iam_role.name
}

output "r53_record_fqdn" {
  description = "The fqdn of the route 53 record."
  value       = aws_route53_record.r53_record.fqdn
}
