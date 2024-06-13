resource "aws_route53_zone" "dns" {
  name = var.dns_zone_name
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 5.0"

  domain_name = "nginx.${aws_route53_zone.dns.name}"
  zone_id     = aws_route53_zone.dns.zone_id

  validation_method = "DNS"

  subject_alternative_names = []

  wait_for_validation = true
  tags = {
    Name = "nginx.${aws_route53_zone.dns.name}"
  }
}