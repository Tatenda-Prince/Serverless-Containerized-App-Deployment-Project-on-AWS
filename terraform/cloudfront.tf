# =============================================================================
# CLOUDFRONT CDN - Global Content Delivery Network
# =============================================================================
# CloudFront provides:
# - Global edge locations for faster loading
# - HTTPS/SSL certificates for secure connections
# - Caching for better performance
# - DDoS protection

# CloudFront Distribution
resource "aws_cloudfront_distribution" "shell_bank_cdn" {
  origin {
    domain_name = aws_lb.alb.dns_name
    origin_id   = "shell-bank-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Shell Bank CDN Distribution"
  default_root_object = "index.html"

  # Cache behavior for frontend (default)
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "shell-bank-alb"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Cache behavior for API calls (no caching)
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "shell-bank-alb"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["*"]

      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # Geographic restrictions (optional)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL Certificate configuration
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name = "shell-bank-cdn"
  }
}

# Note: Origin Access Control is not needed for ALB origins
# OAC is only used for S3 origins, not load balancers