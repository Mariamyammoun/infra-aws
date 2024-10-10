# Définition de la variable pour le nom du serveur
variable "server_name" {
  description = "Le nom de l'instance EC2"
  type        = string
}
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}



# Création d'une instance EC2
resource "aws_instance" "dev_machine" {
  ami                    = "ami-08eb150f611ca277f" 
  instance_type          = "t3.micro"
  key_name               = "mariam-key"           

  tags = {
    Environment = "dev"
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



