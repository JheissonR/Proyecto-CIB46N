resource "aws_s3_bucket" "artifacts" {
  bucket = "migraiac-artifacts-c11"
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_ecr_repository" "app" {
  name = "migraiac-app-c11"
}

resource "aws_iam_role" "codebuild" {
  name = "migraiac-codebuild-c11"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "codebuild.amazonaws.com" } }]
  })
}

resource "aws_iam_role" "codepipeline" {
  name = "migraiac-codepipeline-c11"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "codepipeline.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  name = "migraiac-codebuild-policy-c11"
  role = aws_iam_role.codebuild.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = ["s3:*", "ecr:*", "logs:*"], Effect = "Allow", Resource = "*" }]
  })
}

resource "aws_iam_role_policy" "codepipeline" {
  name = "migraiac-codepipeline-policy-c11"
  role = aws_iam_role.codepipeline.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Action = ["s3:*", "codebuild:*"], Effect = "Allow", Resource = "*" }]
  })
}

resource "aws_codebuild_project" "build" {
  name         = "migraiac-build-c11"
  service_role = aws_iam_role.codebuild.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }
  source {
    type = "CODEPIPELINE"
  }
}

resource "aws_codebuild_project" "test" {
  name         = "migraiac-test-c11"
  service_role = aws_iam_role.codebuild.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:7.0"
    type         = "LINUX_CONTAINER"
  }
  source {
    type = "CODEPIPELINE"
  }
}

resource "aws_codepipeline" "main" {
  name     = "migraiac-pipeline-c11"
  role_arn = aws_iam_role.codepipeline.arn
  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["source"]
      configuration = {
        S3Bucket    = aws_s3_bucket.artifacts.bucket
        S3ObjectKey = "source.zip"
      }
    }
  }
  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = ["build"]
      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "build" {
  name              = "/aws/codebuild/migraiac-build-c11"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "test" {
  name              = "/aws/codebuild/migraiac-test-c11"
  retention_in_days = 7
}

resource "aws_sns_topic" "pipeline" {
  name = "migraiac-pipeline-notifications-c11"
}

resource "aws_cloudwatch_event_rule" "pipeline" {
  name = "migraiac-pipeline-rule-c11"
  event_pattern = jsonencode({
    source = ["aws.codepipeline"]
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.pipeline.name
  target_id = "notify"
  arn       = aws_sns_topic.pipeline.arn
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
