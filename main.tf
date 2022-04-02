provider "aws" {
}

resource "aws_vpc" "vpc_primary" {
    cidr_block = "10.55.0.0/16"
    
    tags = {
        Name = "primary"
    }
}

resource "aws_subnet" "subnet_1" {
    vpc_id = aws_vpc.vpc_primary.id
    cidr_block = "10.55.100.0/24"
    availability_zone = "us-east-1e"

    tags = {
        Name = "subnet_1"
    }
}

output "my-vpc-id" {
    value = aws_vpc.vpc_primary.id
}
