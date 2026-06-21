output "Java Server Public IP" {
  value = aws_instance.java_server.public_ip
}

output "DB Server Private IP" {
  value = aws_instance.db_server.private_ip
}