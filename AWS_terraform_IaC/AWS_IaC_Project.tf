provider "aws" {
    region = "us-east-1"
    profile = "myprofile" # access id and access key are stored in AWS credentials
}

# 1. Create VPC

resource "aws_vpc" "project-vpc" {
  cidr_block       = "10.0.0.0/16"

  tags = {
    Name = "main"
  }
}

# 2. Create Internet Gateway

resource "aws_internet_gateway" "project-gw" {
  vpc_id = aws_vpc.project-vpc.id

}

# 3. Crate Custom Route Table

resource "aws_route_table" "project-route-table" {
  vpc_id = aws_vpc.project-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project-gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.project-gw.id
  }

  tags = {
    Name = "project"
  }
}

# 4. Create a subnet

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.project-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "project-subnet"
  }
}

# 5. Associate subnet with Route Table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.project-route-table.id
}

# 6. Create Security Group to allow port 22,80,443

resource "aws_security_group" "allow_tls" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.project-vpc.id

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_HTTPS" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_HTTP" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_SSH" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

# 7. Create a network interface with an ip in the subnet that was created in step 4

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_tls.id]

}

# 8. Assign an elastic IP to the network interface created in step 7

resource "aws_eip" "one" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.project-gw] # To reference the whole object instead of the id
}

# 9. Create Ubuntu server and install/enable apache2

resource "aws_instance" "web-server-instance" {
    ami = "ami-020cba7c55df1f615"
    instance_type = "t3.micro"
    key_name = "main-key"

    network_interface {
        device_index = 0
        network_interface_id = aws_network_interface.web-server-nic.id
    }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c "echo your very first web server > /var/www/html/index.html"
                EOF
    
    tags = {
        Name = "web-server"
    }

}
