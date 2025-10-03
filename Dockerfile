FROM tiangolo/nginx-rtmp:latest

# This image already has nginx with RTMP module compiled and ready
# Create necessary directories
RUN mkdir -p /var/log/nginx \
    && mkdir -p /var/recordings

# Install gettext-base for envsubst
RUN apt-get update && apt-get install -y gettext-base && rm -rf /var/lib/apt/lists/*

# Copy custom nginx configuration as template
COPY nginx.conf /etc/nginx/nginx.conf.template

# Set proper permissions
RUN chown -R nginx:nginx /var/log/nginx /var/recordings 2>/dev/null || true

# Create startup script
RUN echo '#!/bin/bash\n\
set -e\n\
echo "Substituting environment variables in nginx configuration..."\n\
envsubst "$(printf '\''${%s} '\'' $(env | cut -d= -f1))" < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf\n\
echo "Starting nginx..."\n\
exec nginx -g "daemon off;"' > /docker-entrypoint.sh && chmod +x /docker-entrypoint.sh

# Expose RTMP port (1935) and HTTP ports (80, 443)  
EXPOSE 1935 80 443

CMD ["/docker-entrypoint.sh"]