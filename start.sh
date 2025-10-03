#!/bin/bash

# Simple startup script for the RTMP proxy with SSL

set -e

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found. Please copy .env.example to .env and configure it."
    exit 1
fi

source .env

echo "🚀 Starting NGINX RTMP Proxy with SSL..."
echo "📍 Domain: $DOMAIN"
echo "📧 Email: $EMAIL"

# Check if SSL certificates exist in Docker volume
SSL_EXISTS=$(docker run --rm -v nginx-stream_certbot-etc:/certs alpine:latest sh -c "[ -f /certs/live/$DOMAIN/fullchain.pem ] && echo 'true' || echo 'false'" 2>/dev/null || echo 'false')

if [ "$SSL_EXISTS" = "false" ]; then
    echo "⚠️  No SSL certificates found for $DOMAIN"
    echo "🔒 Generating SSL certificate..."
    ./generate-ssl.sh
else
    echo "✅ SSL certificates found for $DOMAIN"
fi

echo "🚀 Starting services..."
docker compose -f docker-compose.prod.yml up -d

echo ""
echo "🎉 Services are running!"
echo "📊 RTMP Proxy: rtmp://$DOMAIN:1935 (or rtmp://localhost:1935)"
echo "🌐 HTTPS Web Interface: https://$DOMAIN"
echo "🔒 HTTP redirects to HTTPS automatically"
echo ""
echo "WHEP Endpoints:"
echo "  Server 1: https://$DOMAIN/rtc1/v1/whep/?app=live&stream=livestream"
echo "  Server 2: https://$DOMAIN/rtc2/v1/whep/?app=live&stream=livestream"
echo ""
echo "📋 Useful commands:"
echo "  View logs: docker compose -f docker-compose.prod.yml logs -f"
echo "  Stop: docker compose -f docker-compose.prod.yml down"
echo "  Status: docker compose -f docker-compose.prod.yml ps"