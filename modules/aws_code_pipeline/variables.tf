variable "repo_name" {
  type    = string
  default = "test-repo"
}

variable "branch_name" {
  type    = string
  default = "master"
}

variable "build_project" {
  type    = string
  default = "test-dev-build-repo"
}

variable "uri_repo" {
  type    = string
  default = "quangtung20/test"
}

variable "bucket_artifact_name" {
  type = string
}

variable "service-pipeline-name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "ecs_td_service" {
  type = string
}

variable "codebuild-role" {
  type = any
}

variable "build_envs" {
  type = map(string)
}

variable "app_service_path" {
  type = string
}

