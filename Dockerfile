FROM nginx:alpine

# Install build dependencies and RTMP module
RUN apk add --no-cache \
    nginx-mod-rtmp \
    && mkdir -p /var/log/nginx

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create directory for RTMP recordings (optional)
RUN mkdir -p /var/recordings

# Expose RTMP port (1935) and HTTP port (80)
EXPOSE 1935 80

CMD ["nginx", "-g", "daemon off;"]