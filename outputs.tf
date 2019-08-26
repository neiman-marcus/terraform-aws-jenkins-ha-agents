output "lb_arn_suffix" {
  value       = aws_lb.lb.arn_suffix
  description = "The ARN suffix of the load balancer."
}

output "lb_dns_name" {
  value       = aws_lb.lb.dns_name
  description = "The DNS name of the load balancer."
}

output "lb_id" {
  value       = aws_lb.lb.id
  description = "The ID/ARN of the load balancer."
}

output "lb_zone_id" {
  value       = aws_lb.lb.zone_id
  description = "The canonical hosted zone ID of the load balancer."
}

output "r53_record_name" {
  value       = aws_route53_record.r53_record.name
  description = "The name of the route 53 record."
}

output "r53_record_fqdn" {
  value       = aws_route53_record.r53_record.fqdn
  description = "The fqdn of the route 53 record."
}

output "r53_zone_id" {
  value       = data.aws_route53_zone.r53_zone.zone_id
  description = "The route 53 zone id."
}

