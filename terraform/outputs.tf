# =============================================================================
# OUTPUTS - Important Information After Deployment
# =============================================================================
# These outputs show you important URLs and information after deployment

# =============================================================================
# DEPLOYMENT OUTPUTS - Your Shell Bank URLs
# =============================================================================

# CloudFront URL (Primary) - Fast, Secure, Global
output "shell_bank_url" {
  description = "🚀 Shell Bank App (CloudFront CDN - Fast & Secure)"
  value       = "https://${aws_cloudfront_distribution.shell_bank_cdn.domain_name}"
}

# Load Balancer URL (Direct) - For testing
output "direct_url" {
  description = "Direct Load Balancer URL (for testing)"
  value       = "http://${aws_lb.alb.dns_name}"
}

# API URL (CloudFront)
output "api_url" {
  description = "API URL via CloudFront"
  value       = "https://${aws_cloudfront_distribution.shell_bank_cdn.domain_name}/api"
}

# Load balancer DNS (for custom domain setup)
output "load_balancer_dns" {
  description = "Load balancer DNS name"
  value       = aws_lb.alb.dns_name
}

# ECS cluster information
output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.ecs_cluster.name
}

# Service names for monitoring
output "backend_service_name" {
  description = "Backend service name"
  value       = aws_ecs_service.backend_service.name
}

output "frontend_service_name" {
  description = "Frontend service name"
  value       = aws_ecs_service.frontend_service.name
}

# VPC ID for reference
output "vpc_id" {
  description = "VPC ID where everything is deployed"
  value       = aws_vpc.ecs_vpc.id
}