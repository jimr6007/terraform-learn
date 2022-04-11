provider "aws" {
    region = "us-east-1"
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "app-vpc"
  cidr = var.vpc_cidr
  azs             = [var.avail_zone]
  private_subnets = [var.private_subnet]
  public_subnets  = [var.public_subnet]
  public_subnet_tags = { Name = "${var.env_prefix}-pub_subnet" }
  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}


module "appserver" {
  source = "./modules/appserver"
  env_prefix = var.env_prefix
  vpc_id = module.vpc.vpc_id
  subnet_id = module.vpc.public_subnets[0]
  avail_zone = var.avail_zone
  my_ip = var.my_ip
  ssh_pub_key = var.ssh_pub_key
  instance_type = var.instance_type
}
