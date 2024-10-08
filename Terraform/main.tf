# Définition de la variable pour le nom du serveur
variable "server_name" {
  description = "Le nom de l'instance EC2"
  type        = string
}
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}
# Création du groupe de sécurité qui autorise SSH (port 22)
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH access on port 22 in the default VPC"

  # Autorise les connexions SSH (port 22) depuis n'importe quelle adresse IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Vous pouvez limiter ceci à votre adresse IP
  }

  # Autorise toutes les connexions sortantes
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




# Création d'une instance EC2
resource "aws_instance" "my_server" {
  ami                    = "ami-08eb150f611ca277f" 
  instance_type          = "t3.micro"
  key_name               = "mariam-key"   
# Associer le groupe de sécurité pour permettre SSH
  security_groups = [aws_security_group.allow_ssh.name]

  tags = {
    Name = "${var.server_name}-server" 
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
# Output pour récupérer l'adresse IP publique de l'instance EC2
output "instance_public_ip" {
  value = aws_instance.my_server.public_ip
  description = "The public IP address of the EC2 instance"
}



