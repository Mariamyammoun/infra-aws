# Création d'un VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "MyVPC"
  }
}
# Création d'une Internet Gateway
resource "aws_internet_gateway" "my_gateway" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "MariamGateway"
  }
}
# Création d'un sous-réseau public
resource "aws_subnet" "my_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "MariamSubnet"
  }
}

# Création d'une table de routage
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_gateway.id
  }

  tags = {
    Name = "MariamRouteTable"
  }
}

# Association de la table de routage avec le sous-réseau
resource "aws_route_table_association" "my_route_table_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

# Création d'un groupe de sécurité pour SSH
resource "aws_security_group" "my_security_group" {
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Autorise le SSH depuis n'importe quelle IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Tout le trafic sortant autorisé
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

# Création d'une instance EC2
resource "aws_instance" "my_server" {
  ami                    = "ami-08eb150f611ca277f"  # Remplace avec l'AMI souhaitée
  instance_type          = "t3.micro"
  key_name               = "mariam-key"            # Ta clé existante
  vpc_security_group_ids = [aws_security_group.my_security_group.id]  # Utiliser l'ID du groupe de sécurité
  subnet_id              = aws_subnet.my_subnet.id

  tags = {
    Name = "MariamServer"
  }

  # Provisioning pour sauvegarder les infos de l'instance dans S3
  provisioner "local-exec" {
    command = <<EOT
      echo "IP Address: ${self.public_ip}" > instance_info.txt
      echo "Instance State: ${self.instance_state}" >> instance_info.txt
      aws s3 cp instance_info.txt s3://${aws_s3_bucket.my_bucket.bucket}/instance_info.txt
    EOT
  }
}


