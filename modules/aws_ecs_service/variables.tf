variable "fgms_service_namespace" {
  description = "fgms service namespace"
  type        = string
}

variable "fgms_ecs_cluster_id" {
  type = string
}

variable "fgms_private_subnets_ids" {
  type = list(string)
}

variable "fgms_vpc_id" {
  type = string
}

variable "fgms_dns_discovery_id" {
  type = string
}

variable "fgms_task_role" {
  type = any
}

variable "family_name" {
  type = string
}

variable "cpu_size" {
  type = number
}

variable "memory_size" {
  type = number
}

variable "container_image" {
  type = string
}

variable "service_name" {
  type = string
}

variable "container_port" {
  type = number
}

variable "host_port" {
  type = number
}

variable "fgms_td_service_name" {
  type = string
}

variable "container_environment" {
  type    = list(any)
  default = []
}

variable "service_type" {
  type    = string
  default = "private"
}

variable "fgms_alb_id" {
  type    = string
  default = "test-id"
}

variable "ecs_domain_certificate_arn" {
  type    = string
  default = "ecs_domain_certificate_arn"
}
