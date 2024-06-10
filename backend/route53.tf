resource "aws_route53_record" "cloudfront_domain" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cloud_resume_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.cloud_resume_distribution.hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [aws_cloudfront_distribution.cloud_resume_distribution]
}

resource "aws_route53_record" "cloudfront_subdomain" {
  zone_id = var.hosted_zone_id
  name    = var.subdomain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cloud_resume_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.cloud_resume_distribution.hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [aws_cloudfront_distribution.cloud_resume_distribution]
}

resource "aws_route53_record" "CNAME_records" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.hosted_zone_id
}