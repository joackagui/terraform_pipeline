# main.tf
resource "random_id" "sg_suffix" {
  byte_length = 4
}

resource "aws_security_group" "web_sg" {
  name        = "web-sg-${random_id.sg_suffix.hex}"  # 👈 Nombre único
  description = "Allow HTTP traffic"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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

resource "aws_instance" "apache_server" {
  ami           = "ami-0b287e7832eb862f8"  # Amazon Linux 2
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl enable httpd
              systemctl start httpd
              echo "UPB 2025" > /var/www/html/index.html
              EOF

  tags = {
    Name = "apache-upb-2025"
  }
}