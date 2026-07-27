# เฉลย: สิทธิ์ CI อัปโหลดเฉพาะ public/* (แยกจาก dev group ที่อ่านอย่างเดียว)
# Lab ใช้ IAM User จำลอง CI — production ควรเป็น OIDC (GitHub Actions / GitLab)

resource "aws_iam_user" "ci" {
  name = "${var.project_name}-ci"
  tags = { Purpose = "lab-ci-uploader" }
}

resource "aws_iam_user_policy" "ci_uploader" {
  name = "${var.project_name}-ci-put-public"
  user = aws_iam_user.ci.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:AbortMultipartUpload"]
        Resource = ["${aws_s3_bucket.assets.arn}/public/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.assets.arn]
        Condition = {
          StringLike = { "s3:prefix" = ["public/*"] }
        }
      }
    ]
  })
}

output "ci_user_name" {
  value = aws_iam_user.ci.name
}
