data "aws_iam_role" "pipeline_role" {
  name = "AWSCodePipelineServiceRole-us-east-1-ecs-dev-pipeline"
}

data "aws_codestarconnections_connection" "pipeline-github" {
  name = "pipeline-github"
}

resource "aws_codecommit_repository" "repo" {
  repository_name = var.repo_name
}

resource "aws_codebuild_project" "repo-project" {
  name         = var.build_project
  service_role = var.codebuild-role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  source {
    type      = "CODECOMMIT"
    buildspec = "buildspec.yml"
    location  = "https://github.com/quangtung20/uno-repo.git"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:5.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }
}

resource "aws_s3_bucket" "bucket-artifact" {
  bucket = var.bucket_artifact_name
}

# CODEPIPELINE
resource "aws_codepipeline" "service-pipeline" {
  name     = var.service-pipeline-name
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
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        FullRepositoryId = "quangtung20/uno-repo"
        ConnectionArn    = "${data.aws_codestarconnections_connection.pipeline-github.arn}"
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
