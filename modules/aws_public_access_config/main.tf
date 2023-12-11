resource "aws_alb_target_group" "service_tg" {
  name        = "${var.service_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.fgms_vpc_id
  target_type = "ip"
  health_check {
    path = "/healthcheck"
  }
}

resource "aws_alb_listener" "fgms_tg_listener" {
  load_balancer_arn = var.fgms_alb_id
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.ecs_domain_certificate_arn

  default_action {
    target_group_arn = aws_alb_target_group.service_tg.id
    type             = "forward"
  }
}

resource "aws_alb_listener" "http_tg_listener" {
  load_balancer_arn = var.fgms_alb_id
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
