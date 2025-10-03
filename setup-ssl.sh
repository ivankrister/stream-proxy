#!/bin/bash

# SSL Setup and Renewal Script
# This script handles the initial SSL certificate generation and renewal

set -e

# Load environment variables
source .env

echo "🔒 Setting up SSL certificates for domain: $DOMAIN"

# Check if certificates already exist
if [ -d "./certbot/etc/live/$DOMAIN" ]; then
    echo "✅ SSL certificates already exist for $DOMAIN"
else
    echo "🆕 Generating new SSL certificates..."
    
    # Create temporary nginx config for initial certificate generation
    cat > nginx-temp.conf << EOF
events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name $DOMAIN;
        
        location /.well-known/acme-challenge/ {
            root /var/www/html;
        }
        
        location / {
            return 200 "Temporary server for SSL setup";
            add_header Content-Type text/plain;
        }
    }
}
EOF

    # Start temporary nginx container
    docker run -d \
        --name nginx-temp \
        --network nginx-stream_rtmp-network \
        -p 80:80 \
        -v $(pwd)/nginx-temp.conf:/etc/nginx/nginx.conf:ro \
        -v nginx-stream_web-root:/var/www/html \
        nginx:alpine

    # Wait for nginx to start
    sleep 5

    # Generate certificate
    docker run --rm \
        --network nginx-stream_rtmp-network \
        -v nginx-stream_certbot-etc:/etc/letsencrypt \
        -v nginx-stream_certbot-var:/var/lib/letsencrypt \
        -v nginx-stream_web-root:/var/www/html \
        certbot/certbot certonly \
        --webroot \
        --webroot-path=/var/www/html \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        -d $DOMAIN

    # Stop temporary nginx
    docker stop nginx-temp
    docker rm nginx-temp
    rm nginx-temp.conf

    echo "✅ SSL certificates generated successfully!"
fi

echo "🚀 Starting main services..."
docker-compose up -d

echo "🔄 Setting up automatic renewal (every 30 days)..."

# Create renewal script
cat > renew-ssl.sh << 'EOF'
#!/bin/bash
echo "🔄 Checking SSL certificate renewal..."
docker-compose exec certbot certbot renew --quiet
if [ $? -eq 0 ]; then
    echo "✅ Certificate renewal check completed"
    docker-compose exec nginx-rtmp nginx -s reload
    echo "🔄 NGINX reloaded"
else
    echo "❌ Certificate renewal failed"
fi
EOF

chmod +x renew-ssl.sh

echo "📅 To set up automatic renewal, add this to your crontab:"
echo "0 0 1 * * $(pwd)/renew-ssl.sh >> $(pwd)/ssl-renewal.log 2>&1"
echo ""
echo "Run: crontab -e"
echo "And add the above line to run renewal check on the 1st of every month"
echo ""
echo "🎉 SSL setup complete! Your services are now running with SSL at https://$DOMAIN"