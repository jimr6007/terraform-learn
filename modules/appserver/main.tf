resource "aws_security_group" "app_sg" {
    name        = "allow_ssh_nginx"
    description = "Allow ssh and nginx/docker"
    vpc_id      = var.vpc_id

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
    subnet_id = var.subnet_id
    vpc_security_group_ids = [ aws_security_group.app_sg.id ]
    availability_zone = var.avail_zone
    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name
    user_data = "${file("modules/appserver/user_data.sh")}"
    
    tags = {
        Name = "${var.env_prefix}-my_app-server"
    }
}