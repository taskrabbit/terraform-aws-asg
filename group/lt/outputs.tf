# Outputs

output "lt_id" {
  value = coalesce(
    join(",", aws_launch_template.lt.*.id),
    join(",", aws_launch_template.lt_ebs.*.id),
  )
}

output "sg_id" {
  value = aws_security_group.sg_asg.id
}

