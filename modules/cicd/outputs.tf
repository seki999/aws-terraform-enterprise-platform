output "codebuild_project_name" {
  description = "CodeBuild Project 名称；未启用时为 null。"
  value       = try(aws_codebuild_project.terraform[0].name, null)
}

output "codepipeline_name" {
  description = "CodePipeline 名称；未启用时为 null。"
  value       = try(aws_codepipeline.this[0].name, null)
}

output "connection_arn" {
  description = "CodeStar Connection ARN；创建后仍需在控制台授权。"
  value       = try(aws_codestarconnections_connection.github[0].arn, null)
}

