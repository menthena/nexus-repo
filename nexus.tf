provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_security_group" "forward_ports" {
  name = "forward_ports"
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
}

resource "aws_instance" "nexus" {
  ami                    = "ami-09b41389146498041"
  instance_type          = "t2.medium"
  vpc_security_group_ids = [aws_security_group.forward_ports.id]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key)
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
}

