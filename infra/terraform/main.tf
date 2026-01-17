terraform {
  backend "s3" {
    bucket       = "abdelhak-terraform-state-backend"
    key          = "terraform.tfstate"
    region       = "eu-west-3"
    use_lockfile = true
  }
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "tf-vpc"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.10.0/24"
  map_public_ip_on_launch =  true  

  tags = {
    Name = "tf-subnet"
  }
}

resource "aws_network_interface" "example" {
  subnet_id   = aws_subnet.my_subnet.id

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "example" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block        = "0.0.0.0/0"
    gateway_id  = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "example"
  }
}

resource "aws_security_group" "sg" {
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port        = 3001
    to_port          = 3001
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.example.id
}

resource "aws_key_pair" "key" {
  key_name   = "deployer-key"
  public_key = file("../../keys/my_key.pub")
}

resource "aws_instance" "example" {
  ami           = "ami-0ef9bcd5dfb57b968"
  instance_type = "t3.micro"
  key_name = aws_key_pair.key.id
  vpc_security_group_ids  = [aws_security_group.sg.id]
  subnet_id = aws_subnet.my_subnet.id
  tags = {
    Name = "main"
  }
}