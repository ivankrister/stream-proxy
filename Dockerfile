FROM alfg/nginx-rtmp:latest

# Install gettext for envsubst (this image is based on Alpine)
RUN apk add --no-cache gettext

# Create necessary directories with proper permissions
RUN mkdir -p /var/log/nginx /var/recordings && \
    chmod 755 /var/log/nginx /var/recordings

# Copy custom nginx configuration as template
COPY nginx.conf /etc/nginx/nginx.conf.template

# Copy and setup entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Expose RTMP port (1935) and HTTP ports (80, 443)  
EXPOSE 1935 80 443

ENTRYPOINT ["/docker-entrypoint.sh"]