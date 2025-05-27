#!/bin/bash
sudo yum update -y
sudo yum install nginx -y
sudo systemctl start nginx
sudo chkconfig nginx on

cat > /etc/nginx/conf.d/reverse-proxy.conf <<EOF
server {
    listen 8080;
    location / {
        proxy_pass http://${private_ip}:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

sudo nginx -t && systemctl restart nginx