# configure aws provider with proper credentials
provider "aws" {
  region  = "us-east-1"
  profile = "terraform-user"
}

# create default vpc if one does not exit
resource "aws_default_vpc" "default_vpc" {
  tags = {
    Name = "default vpc"
  }
}

# use data source to get all availability zones in region
data "aws_availability_zones" "availability_zones" {}

# create default subnet if one does not exit 
resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.availability_zones.names[0]

  tags = {
    Name = "default subnet"
  }
}

resource "aws_security_group" "ec2_security_group" {
  name        = "docker-server security group"
  description = "allow access on ports 80 and 22"
  vpc_id      = aws_default_vpc.default_vpc.id

  ingress {
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["108.48.102.126/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "docker-server security group"
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

# launch the ec2 instance and install website
resource "aws_instance" "docker_server_ec2" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  key_name               = "newKey"

  tags = {
    Name = "docker-server"
  }
}

# an empty resource block
resource "null_resource" "name" {
  # ssh into the ec2 instance
  connection {
    host = aws_instance.docker_server_ec2.public_ip
    type = "ssh"
    user = "ec2-user"
    private_key = file("~/Téléchargemnts/newKey.pem")
  }

  # copy the password file for the docker hub account
  # from your computer to the ec2 instance
  provisioner "file" {
    destination = "/home/ec2-user/my_password.txt"
    source = "my_password.txt"
  }

  # copy the dockerfile from the computer to the ec2 instance
  provisioner "file" {
    destination = "/home/ec2-user/Dockerfile"
    source = "Dockerfile"
  }

  # copy the build_docker_images.sh from the computer to the ec2 instance
  provisioner "file" {
    destination = "/home/ec2-user/build_docker_images.sh"
    source = "build_docker_images.sh"
  }

  # set permissions and run the build_docker_images.sh file
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /home/ec2-user/build_docker_images.sh",
      "sh /home/ec2-user/build_docker_images.sh",
    ]
  }

  # wait for ec2 to be created
  depends_on = [
    aws_instance.docker_server_ec2
  ]
}

# print the url of the container server
output "container_url" {
  value = join("", ["http://", aws_instance.docker_server_ec2.public_dns])
}