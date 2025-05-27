resource "aws_vpc" "MY-VPC" {
  cidr_block = "192.168.0.0/21"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    key = "Name"
    value = "MY-VPC"
  }
   
}

resource "aws_subnet" "public-subnet" {
  vpc_id = aws_vpc.MY-VPC.id
  availability_zone = "ap-south-1a"
  cidr_block = "192.168.0.0/23"
  map_public_ip_on_launch = true
  tags = {
    key = "Name"
    value= "PUB-SUBNET"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id = aws_vpc.MY-VPC.id
  availability_zone = "ap-south-1a"
  cidr_block = "192.168.2.0/23"
  tags = {
    key = "Name"
    value= "PRV-SUBNET"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.MY-VPC.id
  tags = {
    key = "Name"
    value = "IGW"
  }
}

resource "aws_eip" "elastic-ip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  subnet_id = aws_subnet.public-subnet.id
  allocation_id = aws_eip.elastic-ip.id
  tags = {
    Name = "NAT"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.MY-VPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id

  }
  tags = {
    Name ="public-route"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.MY-VPC.id
  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id

  }
  tags = {
    Name = "private-route"
  }
}
resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "pub-sg" {
  vpc_id = aws_vpc.MY-VPC.id
  
  ingress  {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress  {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress  {
    from_port= 0
    to_port= 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
   tags = {
    Name ="public-sg"
  }

}


resource "aws_security_group" "prv-sg" {
  vpc_id = aws_vpc.MY-VPC.id
  depends_on = [ aws_security_group.pub-sg ]
  ingress  {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress  {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 8000
    to_port = 8000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress  {
    from_port= 0
    to_port= 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name ="prvate-sg"
  }

}

resource "aws_instance" "public-instance" {
  ami = "ami-0af9569868786b23a"
  instance_type = "t2.micro"
  key_name = "tambiprv"
  depends_on = [ aws_instance.private-instance ]
  subnet_id = aws_subnet.public-subnet.id
  security_groups = [aws_security_group.pub-sg.id]
  user_data = templatefile("ngnix.sh", {
    
    private_ip= aws_instance.private-instance.private_ip
  })

  tags = {
    Name = "public-instance"
  }
                
}

resource "aws_instance" "private-instance" {
  ami = "ami-0af9569868786b23a"
  instance_type = "t2.micro"
  key_name  = "tambiprv"
  security_groups = [aws_security_group.prv-sg.id]
  
  #private_ip = data.aws_instance.private-id.private_ip
  
  subnet_id = aws_subnet.private-subnet.id
  
  user_data = <<-EOF
               #!/bin/bash
               sudo yum update -y
               sudo yum install httpd -y
               sudo sytemctl start httpd 
               sudo chkconfig httpd on
               sudo echo "<h1>HELLO WORLD</h1>" > /var/www/html/index.html
               sudo sed -i 's/^Listen 80/Listen 8000/' /etc/httpd/conf/httpd.conf
               sudo systemctl restart httpd 
               EOF
  tags ={
     Name ="private-instance"
  }
}

