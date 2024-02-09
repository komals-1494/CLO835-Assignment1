# Define the provider
provider "aws" {
  region = "us-east-1"
}

# Create an Elastic Container Registry (ECR)
resource "aws_ecr_repository" "webapp_repo" {
  name = "webapp-repo"
}

resource "aws_ecr_repository" "mysql_repo" {
  name = "mysql-repo"
}

# Create a new VPC 
resource "aws_vpc" "main" {
  cidr_block       = "10.50.0.0/16"
  instance_tenancy = "default"
  }

# Add provisioning of the public subnet in the default VPC
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.50.0.0/24"
  availability_zone = "us-east-1a"
}

# Data source for AMI id
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Webserver deployment
resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.web_key.key_name
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups             = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name = "web_instance" 
  }
}

# Adding SSH key to Amazon EC2
resource "aws_key_pair" "web_key" {
  key_name   = "web"
  public_key = file("web.pub")
}

# Security Group
resource "aws_security_group" "web_sg" {

  name        = "web sg"
  description = "Security Group for Ports 80, 8081, 8082, 8083"
  vpc_id      = aws_vpc.main.id

ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "ssh"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

output "ecr_repository_urls" {
  value = {
    webapp = aws_ecr_repository.webapp_repo.repository_url,
    mysql  = aws_ecr_repository.mysql_repo.repository_url
  }
}

output "ec2_public_ip" {
  value = aws_instance.web_server.public_ip
}
