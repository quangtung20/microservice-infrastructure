output "codebuild-role" {
  description = "codebuild-role"
  value       = aws_iam_role.codebuild-role
}

output "fgms_task_role" {
  description = "task excution role for ecs"
  value       = aws_iam_role.fgms_task_role
}
