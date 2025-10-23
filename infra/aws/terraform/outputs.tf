output "ec2_public_ip" {
  value = aws_instance.vm.public_ip
}
output "ecs_ec2_alb_dns" {
  value = aws_lb.alb_ecs.dns_name
}

output "ecs_ec2_url" {
  value = "http://${aws_lb.alb_ecs.dns_name}"
}

# output "api_gateway_url" { value = aws_apigatewayv2_api.http.api_endpoint }
output "public_ip" {
  value = aws_instance.vm.public_ip
}

output "app_url" {
  value = "http://${aws_instance.vm.public_ip}:8080/docs"
}
