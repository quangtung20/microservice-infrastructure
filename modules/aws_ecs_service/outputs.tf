output "fgms_service_namespace" {
  description = "fgms service namespace"
  value       = var.fgms_service_namespace
}

output "fgms_td_service_name" {
  value = aws_ecs_service.fgms_td_service.name
}
