#!/bin/bash

# Simple startup script for the RTMP proxy with SSL

set -e

source .env

echo "🚀 Starting NGINX RTMP Proxy with SSL..."
echo "📍 Domain: $DOMAIN"
echo "📧 Email: $EMAIL"

# Check if SSL certificates exist
if [ ! -d "./certbot/etc/live/$DOMAIN" ] && [ ! -f "/var/lib/docker/volumes/nginx-stream_certbot-etc/_data/live/$DOMAIN/fullchain.pem" ]; then
    echo "⚠️  No SSL certificates found. Running initial SSL setup..."
    ./setup-ssl.sh
else
    echo "✅ SSL certificates found. Starting services..."
    docker compose up -d
fi

echo ""
echo "🎉 Services are running!"
echo "📊 RTMP Proxy: rtmp://localhost:1935"
echo "🌐 HTTPS Web Interface: https://$DOMAIN"
echo "🔒 HTTP redirects to HTTPS automatically"
echo ""
echo "WHEP Endpoints:"
echo "  Server 1: https://$DOMAIN/rtc1/v1/whep/?app=live&stream=livestream"
echo "  Server 2: https://$DOMAIN/rtc2/v1/whep/?app=live&stream=livestream"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop: docker compose down"