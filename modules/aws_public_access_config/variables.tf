variable "fgms_alb_id" {
  type    = string
  default = "test-id"
}

variable "ecs_domain_certificate_arn" {
  type    = string
  default = "ecs_domain_certificate_arn"
}

variable "fgms_vpc_id" {
  type = string
}

variable "service_name" {
  type = string
}
