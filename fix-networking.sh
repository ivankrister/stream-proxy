#!/bin/bash

# Quick Fix Script for Docker Networking Issues

set -e

echo "🔧 Fixing Docker networking issues..."

# Stop all containers
echo "🛑 Stopping all containers..."
docker-compose down --remove-orphans 2>/dev/null || true

# Clean up networks
echo "🧹 Cleaning up Docker networks..."
docker network prune -f

# Remove any dangling containers
echo "🗑️  Removing dangling containers..."
docker container prune -f

# Start services one by one
echo "🚀 Starting nginx service first..."
docker-compose up -d nginx-rtmp

# Wait a bit for nginx to start
sleep 5

echo "🔒 Starting certbot service..."
docker-compose up -d certbot

echo "✅ Services started successfully!"
echo ""
echo "📊 Check status:"
echo "docker-compose ps"
echo ""
echo "📋 View logs:"
echo "docker-compose logs -f"