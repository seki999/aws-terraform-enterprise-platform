output "frontend_bucket_id" {
  description = "私有前端 S3 Bucket ID。"
  value       = aws_s3_bucket.frontend.id
}

output "frontend_bucket_arn" {
  description = "私有前端 S3 Bucket ARN。"
  value       = aws_s3_bucket.frontend.arn
}

output "upload_bucket_id" {
  description = "私有上传 S3 Bucket ID。"
  value       = aws_s3_bucket.uploads.id
}

output "upload_bucket_arn" {
  description = "私有上传 S3 Bucket ARN。"
  value       = aws_s3_bucket.uploads.arn
}

output "access_logs_bucket_id" {
  description = "S3 与 CloudFront 访问日志 Bucket ID。"
  value       = aws_s3_bucket.logs.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID；未启用时为 null。"
  value       = try(aws_cloudfront_distribution.frontend[0].id, null)
}

output "cloudfront_distribution_arn" {
  description = "CloudFront Distribution ARN；未启用时为 null。"
  value       = try(aws_cloudfront_distribution.frontend[0].arn, null)
}

output "frontend_url" {
  description = "前端 HTTPS URL；CloudFront 未启用时为 null。"
  value       = var.enable_cloudfront ? "https://${coalesce(var.domain_name, aws_cloudfront_distribution.frontend[0].domain_name)}" : null
}

