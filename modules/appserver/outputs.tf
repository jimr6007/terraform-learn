output "ami-id" {
    value = data.aws_ami.app_ami.id
}

output "my-instance" {
    value = aws_instance.app_instance
}