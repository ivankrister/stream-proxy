FROM nginx:alpine

# Install dependencies and build nginx with RTMP module
RUN apk add --no-cache \
    build-base \
    pcre-dev \
    zlib-dev \
    openssl-dev \
    git \
    gettext

# Get nginx version and download source
RUN NGINX_VERSION=$(nginx -v 2>&1 | grep -o '[0-9.]*') && \
    cd /tmp && \
    wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar zxf nginx-${NGINX_VERSION}.tar.gz && \
    git clone https://github.com/arut/nginx-rtmp-module.git && \
    cd nginx-${NGINX_VERSION} && \
    ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --with-perl_modules_path=/usr/lib/perl5/vendor_perl \
        --user=nginx \
        --group=nginx \
        --with-compat \
        --with-file-aio \
        --with-threads \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_mp4_module \
        --with-http_random_index_module \
        --with-http_realip_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_sub_module \
        --with-http_v2_module \
        --with-mail \
        --with-mail_ssl_module \
        --with-stream \
        --with-stream_realip_module \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --add-module=../nginx-rtmp-module && \
    make && make install && \
    rm -rf /tmp/*

# Create necessary directories
RUN mkdir -p /var/log/nginx \
    /var/cache/nginx/client_temp \
    /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp \
    /var/cache/nginx/uwsgi_temp \
    /var/cache/nginx/scgi_temp \
    /var/recordings && \
    chown -R nginx:nginx /var/log/nginx /var/recordings /var/cache/nginx

# Copy custom nginx configuration as template
COPY nginx.conf /etc/nginx/nginx.conf.template

# Copy and setup entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Expose RTMP port (1935) and HTTP ports (80, 443)  
EXPOSE 1935 80 443

ENTRYPOINT ["/docker-entrypoint.sh"]