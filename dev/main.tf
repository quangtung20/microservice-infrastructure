provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "dev-fgmt-10122023"
    key    = "dev.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.20"
    }
  }
}

module "vpc" {
  source = "../modules/aws_vpc"
}

module "dns_namespace" {
  source      = "../modules/aws_dns_namespace"
  fgms_vpc_id = module.vpc.fgms_vpc_id
  depends_on  = [module.vpc]
}

module "iam_role" {
  source     = "../modules/aws_iam_role"
  depends_on = [module.vpc]
}

module "rds_mysql" {
  source                     = "../modules/aws_rds"
  fgms_vpc_id                = module.vpc.fgms_vpc_id
  fgms_database_subnet_group = module.vpc.fgms_database_subnet_group
  depends_on                 = [module.vpc]
}

module "ecs" {
  source     = "../modules/aws_ecs"
  depends_on = [module.vpc]
}

module "alb" {
  source                  = "../modules/aws_alb"
  fgms_vpc_id             = module.vpc.fgms_vpc_id
  fgms_public_subnets_ids = module.vpc.fgms_public_subnets_ids
  depends_on              = [module.vpc]
}

module "log_group" {
  source = "../modules/aws_cloudwatch_log_group"
}

module "ecs_due" {
  source                   = "../modules/aws_ecs_service"
  container_image          = "quangtung20/due:latest"
  service_name             = "fgms-due"
  container_port           = 3000
  host_port                = 3000
  cpu_size                 = 256
  memory_size              = 512
  family_name              = "fgms_due_td"
  fgms_dns_discovery_id    = module.dns_namespace.fgms_dns_discovery_id
  fgms_task_role           = module.iam_role.fgms_task_role
  fgms_ecs_cluster_id      = module.ecs.fgms_ecs_cluster_id
  fgms_private_subnets_ids = module.vpc.fgms_private_subnets_ids
  fgms_service_namespace   = "fgms-due-service"
  fgms_td_service_name     = "fgms_due_td_service"
  fgms_vpc_id              = module.vpc.fgms_vpc_id
  depends_on               = [module.vpc, module.alb, module.dns_namespace, module.ecs, module.iam_role, module.rds_mysql]
}

module "ecs_tre" {
  source                   = "../modules/aws_ecs_service"
  container_image          = "quangtung20/tre:latest"
  service_name             = "fgms-tre"
  container_port           = 3000
  host_port                = 3000
  cpu_size                 = 256
  memory_size              = 512
  family_name              = "fgms_tre_td"
  fgms_dns_discovery_id    = module.dns_namespace.fgms_dns_discovery_id
  fgms_task_role           = module.iam_role.fgms_task_role
  fgms_ecs_cluster_id      = module.ecs.fgms_ecs_cluster_id
  fgms_private_subnets_ids = module.vpc.fgms_private_subnets_ids
  fgms_service_namespace   = "fgms-tre-service"
  fgms_td_service_name     = "fgms_tre_td_service"
  fgms_vpc_id              = module.vpc.fgms_vpc_id
  depends_on               = [module.vpc, module.alb, module.dns_namespace, module.ecs, module.iam_role, module.rds_mysql]
}

module "ecs_uno" {
  source                     = "../modules/aws_ecs_service"
  container_image            = "quangtung20/uno:latest"
  service_name               = "fgms-uno"
  container_port             = 3000
  host_port                  = 3000
  cpu_size                   = 256
  memory_size                = 512
  family_name                = "fgms_uno_td"
  fgms_dns_discovery_id      = module.dns_namespace.fgms_dns_discovery_id
  fgms_task_role             = module.iam_role.fgms_task_role
  fgms_ecs_cluster_id        = module.ecs.fgms_ecs_cluster_id
  fgms_private_subnets_ids   = module.vpc.fgms_private_subnets_ids
  fgms_service_namespace     = "fgms-uno-service"
  fgms_td_service_name       = "fgms_uno_td_service"
  fgms_vpc_id                = module.vpc.fgms_vpc_id
  depends_on                 = [module.vpc, module.alb, module.dns_namespace, module.ecs, module.iam_role, module.rds_mysql, module.ecs_due, module.ecs_tre]
  service_type               = "public"
  fgms_alb_id                = module.alb.fgms_alb_id
  ecs_domain_certificate_arn = module.alb.ecs_domain_certificate_arn
  container_environment = [
    {
      name : "DUE_SERVICE_API_BASE",
      value : "http://${module.ecs_due.fgms_service_namespace}.${module.dns_namespace.fgms_private_dns_namespace}"
    },
    {
      name : "TRE_SERVICE_API_BASE",
      value : "http://${module.ecs_tre.fgms_service_namespace}.${module.dns_namespace.fgms_private_dns_namespace}"
    },
    {
      name : "DB_NAME",
      value : "${module.rds_mysql.database_db_name}"
    },
    {
      name : "DB_USERNAME",
      value : "${module.rds_mysql.database_db_user}"
    },
    {
      name : "DB_PASS",
      value : "${module.rds_mysql.database_password}"
    },
    {
      name : "DB_HOST"
      value : "${module.rds_mysql.database_endpoint}"
    }
  ]
}

module "pipeline_due" {
  source                = "../modules/aws_code_pipeline"
  branch_name           = "master"
  bucket_artifact_name  = "pipeline-artifact-due-20231211-bucket"
  build_project         = "due-dev-build-repo"
  cluster_name          = module.ecs.cluster_name
  ecs_td_service        = module.ecs_due.fgms_td_service_name
  repo_name             = "due-repo"
  service-pipeline-name = "due-pipeline"
  codebuild-role        = module.iam_role.codebuild-role
}

# module "pipeline_tre" {
#   source                = "../modules/aws_code_pipeline"
#   branch_name           = "master"
#   bucket_artifact_name  = "pipeline-artifact-tre-20231211-bucket"
#   build_project         = "tre-dev-build-repo"
#   cluster_name          = module.ecs.cluster_name
#   ecs_td_service        = module.ecs_tre.fgms_td_service_name
#   repo_name             = "tre-repo"
#   service-pipeline-name = "tre-pipeline"
#   codebuild-role        = module.iam_role.codebuild-role
# }

# module "pipeline_uno" {
#   source                = "../modules/aws_code_pipeline"
#   branch_name           = "master"
#   bucket_artifact_name  = "pipeline-artifact-uno-20231211-bucket"
#   build_project         = "uno-dev-build-repo"
#   cluster_name          = module.ecs.cluster_name
#   ecs_td_service        = module.ecs_uno.fgms_td_service_name
#   repo_name             = "uno-repo"
#   service-pipeline-name = "uno-pipeline"
#   codebuild-role        = module.iam_role.codebuild-role
# }
