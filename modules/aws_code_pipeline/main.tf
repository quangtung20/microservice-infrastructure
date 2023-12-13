data "aws_iam_role" "pipeline_role" {
  name = "AWSCodePipelineServiceRole-us-east-1-ecs-dev-pipeline"
}

data "aws_codestarconnections_connection" "pipeline_github" {
  name = "pipeline-github"
}

resource "aws_codebuild_project" "repo_project" {
  name         = var.build_project
  service_role = var.codebuild-role.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type      = "CODECOMMIT"
    buildspec = "${var.app_service_path}/buildspec.yml"
    location  = var.uri_repo
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    // truyen dynamic variable
    dynamic "environment_variable" {
      for_each = var.build_envs
      content {
        name  = environment_variable.key
        value = environment_variable.value
      }
    }
  }
}

resource "aws_s3_bucket" "bucket_artifact" {
  bucket = var.bucket_artifact_name
}

# CODEPIPELINE
resource "aws_codepipeline" "service-pipeline" {
  name     = var.service-pipeline-name
  role_arn = data.aws_iam_role.pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.bucket_artifact.bucket
    type     = "S3"
  }
  # SOURCE
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        FullRepositoryId = "${var.repo_name}"
        ConnectionArn    = "${data.aws_codestarconnections_connection.pipeline_github.arn}"
        BranchName       = "${var.branch_name}"
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
        ClusterName = var.cluster_name
        ServiceName = var.ecs_td_service
        FileName    = "imagedefinitions.json"
      }
    }
  }
}
