provider "aws" {
  version = "~> 3.0"
  region  = "us-east-1"
########################
# Use secrets.....or some other way, DO NOT copy access/secret key in this file
########################
  access_key = "###########################"
  secret_key = "###########################"
}

# Create a VPC
resource "aws_vpc" "BrokenByteVPC" {
  cidr_block = "192.168.0.0/16"
  tags = {
    Name = "BrokenByteVPC"
  }
}

resource "aws_subnet" "Brokenbyte-outside" {
  vpc_id     = aws_vpc.BrokenByteVPC.id
  cidr_block = "192.168.100.0/24"
  availability_zone = "us-east-1a"
  #map_public_ip_on_launch = true
  tags = {
    Name = "Brokenbyte-outside"
  }
}

resource "aws_subnet" "Brokenbyte-inside" {
  vpc_id     = aws_vpc.BrokenByteVPC.id
  cidr_block = "192.168.10.0/28"
  availability_zone = "us-east-1a"
 # map_public_ip_on_launch = true
  tags = {
    Name = "Brokenbyte-inside"
  }
}
resource "aws_internet_gateway" "BrokenByte-gateway" {
  vpc_id = aws_vpc.BrokenByteVPC.id

  tags = {
    Name = "BrokenByte-gateway"
  }
}

resource "aws_route_table" "BrokenByte-Route-table" {
  vpc_id = aws_vpc.BrokenByteVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.BrokenByte-gateway.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.Brokenbyte-outside.id
  route_table_id = aws_route_table.BrokenByte-Route-table.id
}


resource "aws_route_table_association" "b"{
  subnet_id      = aws_subnet.Brokenbyte-inside.id
  route_table_id = aws_route_table.BrokenByte-Route-table.id
}

resource "aws_security_group" "allow_traffic" {
  name        = "allow_Traffic"
  description = "Allow SSH,HTTP and HTTPS  inbound traffic"
  vpc_id      = aws_vpc.BrokenByteVPC.id



#################################################
# Just for testing, allow every ingress trafic, every protocol, from ANY IP!!!!
################################################
#ingress {
#   description = "Dozvoli SVEEEEEEEE"
#   from_port   = 0
#   to_port     = 0
#   protocol    = "-1"
#   cidr_blocks = ["0.0.0.0/0"]
# }

ingress {
    description = "SSH traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    description = "HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


#################################################
# Just for testing, allow every ingress trafic, every protocol, from ANY IP!!!!
################################################
#egress {
#   description = "Dozvoli SVEEEEEEEE"
#   from_port   = 0
#   to_port     = 0
#   protocol    = "-1"
#   cidr_blocks = ["0.0.0.0/0"]
# }

  tags = {
    Name = "Allow_ssh_http_https"
  }
}

resource "aws_network_interface" "NginX-public" {
  subnet_id       = aws_subnet.Brokenbyte-outside.id
  #private_ips     = ["192.168.100.10"]
  security_groups = [aws_security_group.allow_traffic.id]
}

resource "aws_network_interface" "NginX-outside" {
  subnet_id       = aws_subnet.Brokenbyte-outside.id
  #private_ips     = ["192.168.10.10"]
  security_groups = [aws_security_group.allow_traffic.id]
}
resource "aws_network_interface" "NginX-inside" {
  subnet_id       = aws_subnet.Brokenbyte-inside.id
  private_ips     = ["192.168.10.10"]
  security_groups = [aws_security_group.allow_traffic.id]
}

resource "aws_network_interface" "www1" {
  subnet_id       = aws_subnet.Brokenbyte-inside.id
  private_ips     = ["192.168.10.11"]
  security_groups = [aws_security_group.allow_traffic.id]
}
resource "aws_network_interface" "www2" {
  subnet_id       = aws_subnet.Brokenbyte-inside.id
  private_ips     = ["192.168.10.12"]
  security_groups = [aws_security_group.allow_traffic.id]
}

resource "aws_network_interface" "www3" {
  subnet_id       = aws_subnet.Brokenbyte-inside.id
  private_ips     = ["192.168.10.13"]
  security_groups = [aws_security_group.allow_traffic.id]
}

resource "aws_eip" "BrokenByte-PublicIP" {
  vpc                       = true
  network_interface         = aws_network_interface.NginX-public.id
  #associate_with_private_ip = "192.168.100.10"
  depends_on = [aws_internet_gateway.BrokenByte-gateway, aws_instance.BrokenByteNginX]
}

resource "aws_instance" "BrokenByteNginX" {
  ami = "ami-0dba2cb6798deb6d8"
  availability_zone = "us-east-1a"
  instance_type = "t2.micro"
  key_name = "aws_test"
  # network_interface {
  #      device_index=0
  #      network_interface_id = aws_network_interface.NginX-LB.id
  # }
    network_interface {
       device_index=0
       network_interface_id = aws_network_interface.NginX-public.id
  }
    network_interface {
       device_index=1
       network_interface_id = aws_network_interface.NginX-inside.id
  }

  
  tags = {
    Name = "lb"
    group = "lb"
  }

  user_data =  <<-EOF
               #!/bin/bash
               hostname nginxlb
               sudo apt-get update -y
               sudo apt-get install nginx -y
               unlink /etc/nginx/sites-enabled/default
               sudo systemctl start nginx
               EOF

}

resource "aws_instance" "BrokenByteWWW1" {
  ami = "ami-0dba2cb6798deb6d8"
  availability_zone = "us-east-1a"
  instance_type = "t2.micro"
  key_name = "aws_test"
  network_interface {
       device_index=0
       network_interface_id = aws_network_interface.www1.id
  }
  tags = {
    Name = "www1"
    group = "www"
  }
user_data =  <<-EOF
               #!/bin/bash
               hostname WWWW1
               sudo apt-get update -y
               sudo apt-get install nginx -y
               sudo systemctl start nginx
               sudo bash -c 'echo WWW1 > /var/www/html/index.html'
               EOF
}

resource "aws_instance" "BrokenByteWWW2" {
  ami = "ami-0dba2cb6798deb6d8"
  availability_zone = "us-east-1a"
  instance_type = "t2.micro"
  key_name = "aws_test"
  network_interface {
       device_index=0
       network_interface_id = aws_network_interface.www2.id
  }
  tags = {
    Name = "www2"
    group = "www"
  }

user_data =  <<-EOF
               #!/bin/bash
               hostname WWWW2
               sudo apt-get update -y
               sudo apt-get install nginx -y
               sudo systemctl start nginx
               sudo bash -c 'echo WWW2 > /var/www/html/index.html'
               EOF
}

resource "aws_instance" "BrokenByteWWW3" {
  ami = "ami-0dba2cb6798deb6d8"
  availability_zone = "us-east-1a"
  instance_type = "t2.micro"
  key_name = "aws_test"
  network_interface {
       device_index=0
       network_interface_id = aws_network_interface.www3.id
  }
  tags = {
    Name = "www3"
    group = "www"
    
  }
  user_data =  <<-EOF
               #!/bin/bash
               hostname WWWW3
               sudo apt-get update -y
               sudo apt-get install nginx -y
               sudo systemctl start nginx
               sudo bash -c 'echo WWW3 > /var/www/html/index.html'
               EOF
}
