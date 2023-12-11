resource "aws_ecs_task_definition" "fgms_td" {
  family                   = var.family_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu_size
  memory                   = var.memory_size
  execution_role_arn       = var.fgms_task_role.arn

  container_definitions = jsonencode(
    [
      {
        cpu : var.cpu_size,
        image : "${var.container_image}",
        memory : var.cpu_size,
        name : "${var.service_name}",
        networkMode : "awsvpc",
        environment : var.container_environment
        portMappings : [
          {
            containerPort : var.container_port,
            hostPort : var.host_port
          }
        ],
        logConfiguration : {
          logDriver : "awslogs",
          options : {
            awslogs-group : "/ecs/fgms_log_group",
            awslogs-region : "us-east-1",
            awslogs-stream-prefix : "${var.service_name}"
          }
        }
      }
    ]
  )


}

resource "aws_ecs_service" "fgms_td_service" {
  name            = var.fgms_td_service_name
  cluster         = var.fgms_ecs_cluster_id
  task_definition = aws_ecs_task_definition.fgms_td.arn
  desired_count   = "1"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = ["${aws_security_group.ecs_tasks_sg.id}"]
    subnets         = ["${var.fgms_private_subnets_ids[0]}"]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.fgms_service.arn
  }

  // if else trong terraform
  dynamic "load_balancer" {
    for_each = var.service_type == "public" ? [1] : []
    content {
      target_group_arn = module.public_access_config[0].service_tg_id
      container_name   = var.service_name
      container_port   = var.container_port
    }
  }
}


resource "aws_security_group" "ecs_tasks_sg" {
  name        = "ecs_tasks_${var.service_name}_sg"
  description = "allow inbound access from the ALB only"
  vpc_id      = var.fgms_vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = "3000"
    to_port     = "3000"
    cidr_blocks = ["13.0.0.0/16"]
  }

  ingress {
    protocol  = -1
    from_port = 0
    to_port   = 0
    self      = true
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_service_discovery_service" "fgms_service" {
  name = var.fgms_service_namespace

  dns_config {
    namespace_id = var.fgms_dns_discovery_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 2
  }
}

module "public_access_config" {
  count                      = var.service_type == "public" ? 1 : 0
  source                     = "../aws_public_access_config"
  fgms_alb_id                = var.fgms_alb_id
  fgms_vpc_id                = var.fgms_vpc_id
  ecs_domain_certificate_arn = var.ecs_domain_certificate_arn
  service_name               = var.service_name
}
//////////////////////////
# resource "aws_alb_target_group" "service_tg" {
#   count       = var.service_type == "public" ? 1 : 0
#   name        = "fgms-uno-tg"
#   port        = 80
#   protocol    = "HTTP"
#   vpc_id      = var.fgms_vpc_id
#   target_type = "ip"
#   health_check {
#     path = "/healthcheck"
#   }
# }

# resource "aws_alb_listener" "fgms_tg_listener" {
#   count             = var.service_type == "public" ? 1 : 0
#   load_balancer_arn = var.fgms_alb_id
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn   = var.ecs_domain_certificate_arn

#   default_action {
#     target_group_arn = aws_alb_target_group.service_tg.id
#     type             = "forward"
#   }
# }

# resource "aws_alb_listener" "http_uno_tg_listener" {
#   count             = var.service_type == "public" ? 1 : 0
#   load_balancer_arn = var.fgms_alb_id
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type = "redirect"
#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }


