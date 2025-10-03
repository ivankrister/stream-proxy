#!/bin/bash

# Standalone SSL Certificate Generator
# This script generates SSL certificates without Docker Compose dependencies

set -e

# Load environment variables
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found. Please copy .env.example to .env and configure it."
    exit 1
fi

source .env

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "❌ Error: DOMAIN and EMAIL must be set in .env file"
    exit 1
fi

echo "🔒 Generating SSL certificate for: $DOMAIN"
echo "📧 Using email: $EMAIL"

# Create docker network if it doesn't exist
docker network create nginx-stream_rtmp-network 2>/dev/null || true

# Create volumes if they don't exist
docker volume create nginx-stream_certbot-etc 2>/dev/null || true
docker volume create nginx-stream_certbot-var 2>/dev/null || true
docker volume create nginx-stream_web-root 2>/dev/null || true

# Start a temporary nginx for ACME challenge
echo "🌐 Starting temporary web server for ACME challenge..."

# Create simple nginx config for ACME challenge
cat > /tmp/nginx-acme.conf << EOF
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name $DOMAIN;
        
        location /.well-known/acme-challenge/ {
            root /var/www/html;
            try_files \$uri =404;
        }
        
        location / {
            return 200 "ACME Challenge Server";
            add_header Content-Type text/plain;
        }
    }
}
EOF

# Start temporary nginx
docker run -d \
    --name nginx-acme-temp \
    --network nginx-stream_rtmp-network \
    -p 80:80 \
    -v /tmp/nginx-acme.conf:/etc/nginx/nginx.conf:ro \
    -v nginx-stream_web-root:/var/www/html \
    nginx:alpine

echo "⏳ Waiting for nginx to start..."
sleep 5

# Generate certificate
echo "📜 Requesting SSL certificate from Let's Encrypt..."
docker run --rm \
    --network nginx-stream_rtmp-network \
    -v nginx-stream_certbot-etc:/etc/letsencrypt \
    -v nginx-stream_certbot-var:/var/lib/letsencrypt \
    -v nginx-stream_web-root:/var/www/html \
    certbot/certbot certonly \
    --webroot \
    --webroot-path=/var/www/html \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    --non-interactive \
    --expand \
    -d "$DOMAIN"

# Stop and remove temporary nginx
echo "🧹 Cleaning up temporary server..."
docker stop nginx-acme-temp
docker rm nginx-acme-temp
rm /tmp/nginx-acme.conf

echo "✅ SSL certificate generated successfully!"
echo "📁 Certificate location: /etc/letsencrypt/live/$DOMAIN/"
echo ""
echo "🚀 You can now start your services with:"
echo "   docker compose -f docker-compose.prod.yml up -d"