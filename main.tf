# main.tf
resource "aws_security_group" "web_sg" {
  name        = "web-sg-1"
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
  ami           = "ami-0e9a77f74db6ee25d"  
  instance_type = "t2.micro"
  security_groups = [aws_security_group.web_sg.name]

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
