output "ec2_public_ip" { value = aws_instance.vm.public_ip }
output "fargate_service_url" { value = aws_lb.lb.dns_name }
output "api_gateway_url" { value = aws_apigatewayv2_api.http.api_endpoint }