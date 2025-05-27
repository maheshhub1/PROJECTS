
output "private_instance_id" {
  value = aws_instance.private-instance.id
}

output "private_instance_private_ip" {
  value = aws_instance.private-instance.private_ip
}

/*output "privat-ip" {
  value = data.aws_instance.private-id.private_ip
}*/

