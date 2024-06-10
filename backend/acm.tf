resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  subject_alternative_names = [var.subdomain_name]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Tier = "Backend"
  })
}

resource "aws_acm_certificate_validation" "cert_validation" {
  timeouts {
    create = "5m"
  }
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.CNAME_records : record.fqdn]
}
