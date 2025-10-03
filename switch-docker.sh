#!/bin/bash

# Script to switch between different NGINX RTMP configurations
# Usage: ./switch-docker.sh [tiangolo|custom-build]

set -e

OPTION=${1:-tiangolo}

case $OPTION in
    "tiangolo")
        echo "🔄 Switching to tiangolo/nginx-rtmp image..."
        cp Dockerfile Dockerfile.bak 2>/dev/null || true
        
        cat > Dockerfile << 'EOF'
FROM tiangolo/nginx-rtmp:latest

# This image already has nginx with RTMP module compiled and ready
# Create necessary directories
RUN mkdir -p /var/log/nginx \
    && mkdir -p /var/recordings

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Set proper permissions
RUN chown -R nginx:nginx /var/log/nginx /var/recordings 2>/dev/null || true

# Expose RTMP port (1935) and HTTP ports (80, 443)  
EXPOSE 1935 80 443

CMD ["nginx", "-g", "daemon off;"]
EOF

        # Update nginx.conf to not load the module (built-in)
        sed -i.bak 's/^load_module/#load_module/' nginx.conf
        echo "✅ Switched to tiangolo/nginx-rtmp image"
        echo "📝 RTMP module load disabled (built-in)"
        ;;
        
    "custom-build")
        echo "🔄 Switching to custom-built RTMP module..."
        cp Dockerfile.build-rtmp Dockerfile
        cp nginx-custom.conf nginx.conf
        echo "✅ Switched to custom-built RTMP configuration"
        echo "📝 RTMP module will be built from source"
        ;;
        
    *)
        echo "❌ Unknown option: $OPTION"
        echo "Usage: $0 [tiangolo|custom-build]"
        echo ""
        echo "Options:"
        echo "  tiangolo      - Use tiangolo/nginx-rtmp (fast, pre-built)"
        echo "  custom-build  - Build RTMP module from source (compatible, slower)"
        exit 1
        ;;
esac

echo ""
echo "🚀 Ready to build with:"
echo "docker compose -f docker-compose.prod.yml up -d --build"