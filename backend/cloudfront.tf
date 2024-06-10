resource "aws_cloudfront_distribution" "cloud_resume_distribution" {
  origin {
    domain_name = aws_s3_bucket.domain.bucket_regional_domain_name
    origin_id   = var.domain_name
  }

  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "index.html"

  aliases = [var.domain_name, var.subdomain_name]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.domain_name

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 86400
    default_ttl            = 604800
    max_ttl                = 1209600
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA"]
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  depends_on = [aws_acm_certificate.cert]

  tags = merge(var.tags)
}
