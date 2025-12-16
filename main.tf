# main.tf
resource "random_id" "sg_suffix" {
  byte_length = 4
}

# hola

resource "aws_security_group" "web_sg" {
  name        = "web-sg-${random_id.sg_suffix.hex}"  # 👈 Nombre único
  description = "Allow HTTP traffic"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]  # Add IPv6 support
  }

  ingress {
    description = "SSH from anywhere"
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
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "apache_server" {
  ami           = "ami-0b287e7832eb862f8"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              
              # ============================================
              # COMPLETE APACHE INSTALLATION WITH DEBUGGING
              # ============================================
              
              # Set bash to exit on any error
              set -e
              
              # Create comprehensive log file
              exec > >(tee /var/log/user-data-full.log) 2>&1
              echo "=== USER DATA SCRIPT STARTED $(date) ==="
              
              # 1. Update system
              echo "1. Updating system packages..."
              yum update -y
              
              # 2. Install Apache
              echo "2. Installing Apache..."
              yum install -y httpd
              
              # 3. Create a proper HTML page
              echo "3. Creating web content..."
              cat > /var/www/html/index.html << 'EOP'
              <!DOCTYPE html>
              <html>
              <head>
                  <title>UPB 2025 - Terraform + GitHub Actions</title>
                  <style>
                      body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }
                      .container { background: rgba(255,255,255,0.1); padding: 30px; border-radius: 15px; display: inline-block; }
                      h1 { font-size: 3em; margin-bottom: 20px; }
                      .ip { font-family: monospace; background: rgba(0,0,0,0.2); padding: 10px; border-radius: 5px; }
                      .success { color: #4CAF50; font-weight: bold; }
                  </style>
              </head>
              <body>
                  <div class="container">
                      <h1>🚀 UPB 2025</h1>
                      <h2>Terraform + GitHub Actions Success!</h2>
                      <p>Instance IP: <span class="ip">$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)</span></p>
                      <p>Deployed: <span class="success">$(date)</span></p>
                      <p>Apache Status: <span id="status">Checking...</span></p>
                  </div>
                  <script>
                      // Auto-check Apache status
                      fetch('/').then(r => {
                          document.getElementById('status').innerHTML = '<span class="success">✅ RUNNING</span>';
                      }).catch(e => {
                          document.getElementById('status').innerHTML = '❌ OFFLINE';
                      });
                  </script>
              </body>
              </html>
              EOP
              
              # 4. Fix permissions
              echo "4. Setting permissions..."
              chown -R apache:apache /var/www/html
              chmod -R 755 /var/www/html
              
              # 5. Start Apache with detailed logging
              echo "5. Starting Apache service..."
              systemctl enable httpd
              
              # Check if Apache config is valid
              echo "6. Testing Apache configuration..."
              if httpd -t; then
                  echo "Apache configuration test: PASSED"
                  systemctl start httpd
                  sleep 3  # Give Apache time to start
              else
                  echo "Apache configuration test: FAILED"
                  httpd -t  # Show the actual error
                  exit 1
              fi
              
              # 6. Verify Apache is running
              echo "7. Verifying Apache status..."
              if systemctl is-active --quiet httpd; then
                  echo "✅ Apache is ACTIVE and RUNNING"
                  systemctl status httpd --no-pager
              else
                  echo "❌ Apache is NOT running"
                  journalctl -u httpd --no-pager | tail -20
                  exit 1
              fi
              
              # 7. Test Apache from inside the instance (FIXED LINE)
              echo "8. Testing Apache locally..."
              HTTP_RESPONSE=$(curl -s -o /dev/null -w "%%{http_code}" http://localhost)
              if [ "$HTTP_RESPONSE" = "200" ] || [ "$HTTP_RESPONSE" = "301" ] || [ "$HTTP_RESPONSE" = "302" ]; then
                  echo "✅ Local Apache test: SUCCESS (HTTP $HTTP_RESPONSE)"
              else
                  echo "❌ Local Apache test: FAILED (HTTP $HTTP_RESPONSE)"
                  # Don't exit here, continue to debug
              fi
              
              # 8. Open firewall if needed (Amazon Linux 2/2023)
              echo "9. Configuring firewall..."
              if command -v firewall-cmd &> /dev/null; then
                  firewall-cmd --permanent --add-service=http
                  firewall-cmd --permanent --add-service=https
                  firewall-cmd --reload
                  echo "Firewall configured"
              fi
              
              # 9. Create a health check endpoint
              echo "10. Creating health check..."
              echo '{"status": "healthy", "timestamp": "'$(date)'", "service": "apache"}' > /var/www/html/health.json
              
              echo "=== USER DATA SCRIPT COMPLETED SUCCESSFULLY $(date) ==="
              
              # Final verification
              echo "FINAL CHECKS:"
              echo "- Apache process: $(ps aux | grep httpd | grep -v grep | wc -l) workers"
              echo "- Listening on port 80: $(ss -tlnp | grep ':80' || echo 'NOT LISTENING')"
              echo "- IP Address: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
              echo "- Can we reach Apache? $(curl -s -o /dev/null -w '%%{http_code}' http://localhost && echo 'YES' || echo 'NO')"
              EOF

  tags = {
    Name = "apache-upb-2025"
  }
}