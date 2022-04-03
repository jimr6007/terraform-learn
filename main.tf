provider "aws" {
    region = "us-east-1"
}

variable env_prefix {}
variable avail_zone {}
variable vpc_cidr {}
variable subnet_cidr {}
variable my_ip {}


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

data "aws_ami" "my_ami" {
    most_recent      = true
    name_regex       = "^amzn2-ami-"
    owners           = ["amazon"]
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
    filter {
        name = "architecture"
        values = ["x86_64"]
    }
}

resource "aws_instance" "app_instance" {
    ami = data.aws_ami.my_ami.id
    instance_type = "t3.nano"

    tags = {
        Name = "my_app"
    }
}



# output "name" {
#     value = data.aws_ami.my_ami.id
# }

