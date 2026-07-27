output "bucket_name" {
  value       = aws_s3_bucket.assets.id
  description = "Private assets bucket"
}

output "asg_name" {
  value = aws_autoscaling_group.web.name
}

output "iam_group_name" {
  value = aws_iam_group.devs.name
}

output "instance_profile" {
  value = aws_iam_instance_profile.ec2.name
}
