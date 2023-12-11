data "terraform_remote_state" "pipeline" {
  backend = "s3"
  config = {
    bucket = "fgms-infra-05122023"
    key    = "cicd.tfstate"
    region = "us-east-1"
  }
}

data "aws_iam_role" "pipeline_role" {
  name = "AWSCodePipelineServiceRole-us-east-1-ecs-dev-pipeline"
}

resource "aws_codecommit_repository" "repo" {
  repository_name = var.repo_name
}

resource "aws_codebuild_project" "repo-project" {
  name         = var.build_project
  service_role = data.terraform_remote_state.pipeline.outputs.codebuild-role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type     = "CODECOMMIT"
    location = aws_codecommit_repository.repo.clone_url_http
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }
}

resource "aws_s3_bucket" "bucket-artifact" {
  bucket = "eroz-artifactory-uno-20231206-bucket"
  acl    = "private"
}

# CODEPIPELINE
resource "aws_codepipeline" "pipeline" {
  name     = "uno-pipeline"
  role_arn = data.aws_iam_role.pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.bucket-artifact.bucket
    type     = "S3"
  }
  # SOURCE
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = "${var.repo_name}"
        BranchName     = "${var.branch_name}"
      }
    }
  }
  # BUILD
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = "${var.build_project}"
      }
    }
  }
  # DEPLOY
  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = "fgms_ecs_cluster"
        ServiceName = "fgms_uno_td_service"
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
