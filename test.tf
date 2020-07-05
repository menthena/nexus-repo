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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC942fpHCOJkVNAWcUIQV1Wr50f6EZ80BhyGJZM+BA33OTQiR4aWfkFni4D2PKqpRjgrEVcl2c3mp2C7GiYPkoMGulynA+dPlhiox5ZgX6fzJvNcLAmWtt/V87q4YtFT+Vxs6+ncfJt8m1XNx06XJmfxr1HyUquS2GYiZHncBTXWmX60VuLyQtnh+fT9lzVu8ZMVGlpbrPATv73DNcAQQoM3lbIZ/jBfG0C1yFKaetBI41Sddn79f3jEiy+5egAB7ZKikyXdUtqh/yhMX55yyiPtTb4KMlMuJCwRA/fv2JtNIrLqfYFpXdrs6XtFxFNPO8cZz8r4wan/soMaG4CYRAjJeegoK6BpX9NdQ0+ZP/KgoPkQXTV0wSKIv9vqazfdlGINki1HZg8i41EP0YWHPXb6e0F1yayPbnKodZdX1X8MuEzAYYRvSu2qAflmP8djhrvEVawHZJMhPvLwtYmQ30eNVPPMwaeMZEx+UrQHcTP3Q4HezFFonaYSVKpDjGkz0WO0s28bGA6GpfrcmGvsEx/ocwX9Zi6xeq68YtqWC6yI377k6PwjRSkkrFUMjSW50yCxuaoa2P9MGv4cyNC27g1iW4mfVAbVRJsOEc3Qb6TM3cKTCSDu+jxfDrFYq3+rMTul7+chCNTEBIPjHxp0Osxctju3bfbOrmfeMg+WE4SAQ== aatasoy@ldcl167330m"
}

resource "aws_instance" "nexus" {
  ami                    = "ami-0330ffc12d7224386"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.open_ssh.id]
  key_name               = aws_key_pair.deployer.key_name
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/terraform")
    host        = self.public_ip
  }
  provisioner "file" {
    source      = "conf/docker-compose.yaml"
    destination = "/tmp/docker-compose.yaml"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir /etc/nexus",
      "sudo cp /tmp/docker-compose.yaml /etc/nexus/docker-compose.yaml",
      "sudo yum update -y",
      "sudo yum install -y docker",
      "sudo service docker start",
      "sudo usermod -a -G docker ec2-user",
      "sudo mkdir /etc/docker/nexus-data",
      "sudo chown -R 200 /etc/docker/nexus-data",
      "cd /etc/nexus",
      "sudo curl -L \"https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose",
      "docker-compose up -d",
    ]
  }
}



