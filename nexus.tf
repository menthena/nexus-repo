provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_security_group" "open_ssh" {
  name = "open_ssh"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_key_pair" "deployer" {
#   key_name   = "deployer-key"
#   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC942fpHCOJkVNAWcUIQV1Wr50f6EZ80BhyGJZM+BA33OTQiR4aWfkFni4D2PKqpRjgrEVcl2c3mp2C7GiYPkoMGulynA+dPlhiox5ZgX6fzJvNcLAmWtt/V87q4YtFT+Vxs6+ncfJt8m1XNx06XJmfxr1HyUquS2GYiZHncBTXWmX60VuLyQtnh+fT9lzVu8ZMVGlpbrPATv73DNcAQQoM3lbIZ/jBfG0C1yFKaetBI41Sddn79f3jEiy+5egAB7ZKikyXdUtqh/yhMX55yyiPtTb4KMlMuJCwRA/fv2JtNIrLqfYFpXdrs6XtFxFNPO8cZz8r4wan/soMaG4CYRAjJeegoK6BpX9NdQ0+ZP/KgoPkQXTV0wSKIv9vqazfdlGINki1HZg8i41EP0YWHPXb6e0F1yayPbnKodZdX1X8MuEzAYYRvSu2qAflmP8djhrvEVawHZJMhPvLwtYmQ30eNVPPMwaeMZEx+UrQHcTP3Q4HezFFonaYSVKpDjGkz0WO0s28bGA6GpfrcmGvsEx/ocwX9Zi6xeq68YtqWC6yI377k6PwjRSkkrFUMjSW50yCxuaoa2P9MGv4cyNC27g1iW4mfVAbVRJsOEc3Qb6TM3cKTCSDu+jxfDrFYq3+rMTul7+chCNTEBIPjHxp0Osxctju3bfbOrmfeMg+WE4SAQ== aatasoy@ldcl167330m"
#   # private_key = "${file(var.private_key)}"
# }

resource "aws_instance" "nexus" {
  ami                    = "ami-09b41389146498041"
  instance_type          = "t2.medium"
  vpc_security_group_ids = [aws_security_group.open_ssh.id]
  # key_name               = aws_key_pair.deployer.key_name
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key) # todo
    host        = self.public_ip
  }
  provisioner "local-exec" {
    command = <<EOT
      >nexus.tfstate.ini;
      echo "[nexus]" | tee -a nexus.tfstate.ini;
      echo "${aws_instance.nexus.public_ip} ansible_user=${var.ansible_user} ansible_ssh_private_key_file=${var.private_key}" | tee -a nexus.tfstate.ini;
      export ANSIBLE_HOST_KEY_CHECKING=False;
      ansible-playbook -u ${var.ansible_user} --private-key ${var.private_key} -i nexus.tfstate.ini playbook.yml
    EOT
  }

  tags = {
    Name = "nexus"
  }
  volume_tags = {
    Name = "nexus-volume"
  }
}

# resource "aws_ebs_volume" "nexus-volume" {
#   availability_zone = "eu-west-2c"
#   type              = "gp2"
#   size              = 1
#   tags = {
#     Name = "nexus-volume"
#   }
# }

# resource "aws_volume_attachment" "nexus-volume-attachment" {
#   device_name  = "/dev/sdc"
#   volume_id    = "${aws_ebs_volume.nexus-volume.id}"
#   instance_id  = "${aws_instance.nexus.id}"
#   skip_destroy = true
# }
