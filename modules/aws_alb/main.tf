resource "aws_acm_certificate" "ecs_domain_certificate" {
  domain_name       = "api.tranquangtung.click"
  validation_method = "DNS"

  tags = {
    Name = "tranquangtung.click-Certificate"
  }
}

data "aws_route53_zone" "ecs_domain" {
  name         = "tranquangtung.click"
  private_zone = false
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for ecs in aws_acm_certificate.ecs_domain_certificate.domain_validation_options : ecs.domain_name => {
      name   = ecs.resource_record_name
      record = ecs.resource_record_value
      type   = ecs.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.ecs_domain.zone_id
}

resource "aws_acm_certificate_validation" "ecs_domain_certificate_validation" {
  certificate_arn         = aws_acm_certificate.ecs_domain_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_lb" "fgms_alb" {
  load_balancer_type = "application"
  subnets            = var.fgms_public_subnets_ids
  security_groups    = ["${aws_security_group.fgms_alb_sg.id}"]
}

resource "aws_security_group" "fgms_alb_sg" {
  description = "controls access to the ALB"
  vpc_id      = var.fgms_vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route53_record" "ecs_load_balancer_record" {
  name    = "api.tranquangtung.click"
  type    = "A"
  zone_id = data.aws_route53_zone.ecs_domain.zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_lb.fgms_alb.dns_name
    zone_id                = aws_lb.fgms_alb.zone_id
  }
}
