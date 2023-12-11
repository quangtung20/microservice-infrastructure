variable "fgms_tre_service_namespace" {
  description = "fgms tre service namespace"
  default     = "fgms-tre-service"
}

variable "repo_name" {
  type    = string
  default = "tre-repo"
}

variable "branch_name" {
  type    = string
  default = "master"
}

variable "build_project" {
  type    = string
  default = "tre-dev-build-repo"
}

variable "uri_repo" {
  type    = string
  default = "quangtung20/tre"
}
