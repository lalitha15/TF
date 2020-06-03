## creating instance with user-defined SECURITY GROUP and running apache webserver

variable "access_key" {}
variable "secret_key" {}
variable "region" {
  default = "us-east-2"
}

variable "key_pair_name" {}

provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region     = "${var.region}"
} 

## Security Group##
resource "aws_security_group" "terraform_private_sg" {
  description = "Allow limited inbound external traffic"
  name        = "terraform_ec2_private_sg"

  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
  }

  ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
  }

  egress {
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }

  tags = {
    Name = "ec2-private-sg"
  }
}

output "aws_security_gr_id" {
  value = "${aws_security_group.terraform_private_sg.id}"
}

resource "aws_instance" "terraform_wapp" {
    ami = "ami-026dea5602e368e96"
    instance_type = "t2.micro"
    vpc_security_group_ids = [ "${aws_security_group.terraform_private_sg.id}" ]
    key_name               = "${var.key_pair_name}"
    count         = 1
    associate_public_ip_address = true
    user_data     = <<-EOF
                  #!/bin/bash
                  sudo su
                  yum -y install httpd
                  publicip=$(dig TXT +short o-o.myaddr.l.google.com @ns1.google.com)
                  echo "Hello from $publicip" >> /var/www/html/index.html
                  sudo systemctl enable httpd
                  sudo systemctl start httpd
                  EOF
    tags = {
      Name              = "terraform_ec2_dev"
      Environment       = "development"
    }
}
