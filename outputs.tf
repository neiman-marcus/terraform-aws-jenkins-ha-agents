output "agent_asg" {
  description = "The name of the agent asg. Use for adding to addition outside resources."
  value       = aws_autoscaling_group.agent_asg.name
}

output "agent_iam_role" {
  description = "The agent IAM role attributes. Use for attaching additional iam policies."
  value       = aws_iam_role.agent_iam_role.name
}

output "efs_arn" {
  description = "ARN of the EFS share, so you can use it elsewhere."
  value = aws_efs_file_system.master_efs.arn
}

output "lb_dns_name" {
  value       = aws_lb.lb.dns_name
  description = "The DNS name of the load balancer."
}

output "lb_zone_id" {
  value       = aws_lb.lb.zone_id
  description = "The canonical hosted zone ID of the load balancer."
}

output "master_asg" {
  description = "The name of the master asg. Use for adding to addition outside resources."
  value       = aws_autoscaling_group.master_asg.name
}

output "master_iam_role" {
  description = "The master IAM role name. Use for attaching additional iam policies."
  value       = aws_iam_role.master_iam_role.name
}

output "r53_record" {
  description = "The fqdn of the route 53 record."
  value       = aws_route53_record.r53_record.fqdn
}
