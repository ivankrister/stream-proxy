#!/bin/bash
set -e

echo "Starting NGINX RTMP Proxy..."
echo "Environment variables:"
echo "WHEP_SERVER_1=$WHEP_SERVER_1"
echo "WHEP_HOST_1=$WHEP_HOST_1"
echo "WHEP_SERVER_2=$WHEP_SERVER_2"
echo "WHEP_HOST_2=$WHEP_HOST_2"
echo "ORYX_SERVER_1=$ORYX_SERVER_1"
echo "ORYX_SERVER_2=$ORYX_SERVER_2"
echo "DOMAIN=$DOMAIN"

echo "Substituting environment variables in nginx configuration..."

# Use envsubst to substitute environment variables
envsubst '${WHEP_SERVER_1} ${WHEP_HOST_1} ${WHEP_SERVER_2} ${WHEP_HOST_2} ${ORYX_SERVER_1} ${ORYX_SERVER_2} ${DOMAIN}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "Generated nginx configuration:"
echo "--- BEGIN CONFIG ---"
head -30 /etc/nginx/nginx.conf
echo "--- END CONFIG (first 30 lines) ---"

echo "Testing nginx configuration..."
nginx -t

echo "Starting nginx..."
exec nginx -g "daemon off;"