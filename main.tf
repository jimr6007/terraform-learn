provider "aws" {
    region = "us-east-1"
}

variable env_prefix {}
variable avail_zone {}
variable vpc_cidr {}
variable subnet_cidr {}
variable instance_type {}
variable my_ip {}
variable "ssh_pub_key" {}
variable "user_data_script" {}


resource "aws_vpc" "app_vpc" {
    cidr_block = var.vpc_cidr

    tags = {
        Name = "${var.env_prefix}-vpc"
        Environment = var.env_prefix
    }
}

resource "aws_subnet" "app_subnet_1" {
    vpc_id = aws_vpc.app_vpc.id
    cidr_block = var.subnet_cidr
    availability_zone = var.avail_zone

    tags = {
        Name = "${var.env_prefix}-subnet_1"
        Environment = var.env_prefix
    }
}

resource "aws_internet_gateway" "app_igw" {
    vpc_id = aws_vpc.app_vpc.id

    tags = {
        Name = "${var.env_prefix}-igw"
    }
}


resource "aws_route_table" "app_rtb" {
    vpc_id = aws_vpc.app_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.app_igw.id
    }

    tags = {
        Name = "${var.env_prefix}-rtb"
    }
}

resource "aws_route_table_association" "app_rtb_assoc" {
    route_table_id = aws_route_table.app_rtb.id
    subnet_id = aws_subnet.app_subnet_1.id
}

resource "aws_security_group" "app_sg" {
    name        = "allow_ssh_nginx"
    description = "Allow ssh and nginx/docker"
    vpc_id      = aws_vpc.app_vpc.id

    ingress {
        description      = "inbound ssh"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = [var.my_ip]
    }
    ingress {
        description      = "inbound nginx"
        from_port        = 8080
        to_port          = 8080
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }
    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.env_prefix}-sg"
    }
}

data "aws_ami" "app_ami" {
    most_recent      = true
    owners           = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-kernel-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
    filter {
        name = "architecture"
        values = ["x86_64"]
    }
}

resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    public_key = var.ssh_pub_key
}

resource "aws_instance" "app_instance" {
    ami = data.aws_ami.app_ami.id
    instance_type = var.instance_type
    subnet_id = aws_subnet.app_subnet_1.id
    vpc_security_group_ids = [ aws_security_group.app_sg.id ]
    availability_zone = var.avail_zone
    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

    user_data = file(var.user_data_script)

    tags = {
        Name = "${var.env_prefix}-my_app-server"
    }
}

output "ami-id" {
    value = data.aws_ami.app_ami.id
}

output "ec2-instance-public-ip" {
    value = aws_instance.app_instance.public_ip
}
