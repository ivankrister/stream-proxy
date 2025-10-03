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