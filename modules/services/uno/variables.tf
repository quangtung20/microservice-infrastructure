variable "fgms_uno_service_namespace" {
  description = "fgms uno service namespace"
  default     = "fgms-uno-service"
}

variable "repo_name" {
  type    = string
  default = "uno-repo"
}

variable "branch_name" {
  type    = string
  default = "master"
}

variable "build_project" {
  type    = string
  default = "uno-dev-build-repo"
}

variable "uri_repo" {
  type    = string
  default = "quangtung20/uno"
}
