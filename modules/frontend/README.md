# Frontend 模块

创建三个私有 S3 Bucket（前端、上传、访问日志）、版本控制、加密、生命周期、S3 Access Logging，以及可选 CloudFront、OAC、ACM、Route 53 和 WAF。

CloudFront 自定义证书由 `aws.us_east_1` Provider 创建。未提供域名时使用 CloudFront 默认域名，不会假设或占用真实 DNS。S3 不允许公开读取，CloudFront 仅通过带 Distribution SourceArn 条件的 OAC Policy 读取。

CloudFront、WAF 和自定义域名默认可关闭。访问日志 Bucket 为兼容 S3/CloudFront 日志交付采用 `BucketOwnerPreferred`，其余 Bucket 使用严格 Public Access Block。

