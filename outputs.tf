output "ec2-public-ip" {
  value = module.appserver.my-instance.public_ip
  
}