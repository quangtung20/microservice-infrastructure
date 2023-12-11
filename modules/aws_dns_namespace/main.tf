resource "aws_service_discovery_private_dns_namespace" "fgms_dns_discovery" {
  name        = var.fgms_private_dns_namespace
  description = "fgms dns discovery"
  vpc         = var.fgms_vpc_id
}
