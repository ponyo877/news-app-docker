#!/bin/bash

# System Resource Monitoring Script
# Usage: Run this script periodically via cron to monitor system resources

LOG_DIR="/var/log/news-app-monitoring"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Create log directory if it doesn't exist
sudo mkdir -p "$LOG_DIR"

# Memory monitoring
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.1f", $3/$2*100}')
SWAP_USAGE=$(free | awk 'NR==3{if($2>0) printf "%.1f", $3/$2*100; else print "0"}')

# Disk monitoring
DISK_USAGE=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//')

# Docker stats
DOCKER_STATS=$(sudo docker stats --no-stream --format "{{.Name}}: CPU={{.CPUPerc}} MEM={{.MemUsage}}")

# Log to file
echo "[$DATE] Memory: ${MEMORY_USAGE}% | Swap: ${SWAP_USAGE}% | Disk: ${DISK_USAGE}%" >> "$LOG_DIR/system.log"
echo "[$DATE] Docker Stats:" >> "$LOG_DIR/docker.log"
echo "$DOCKER_STATS" >> "$LOG_DIR/docker.log"

# Alert if memory usage is high
if (( $(echo "$MEMORY_USAGE > 85" | bc -l) )); then
    echo "[$DATE] ALERT: High memory usage: ${MEMORY_USAGE}%" >> "$LOG_DIR/alerts.log"
fi

# Alert if disk usage is high
if [ "$DISK_USAGE" -gt 85 ]; then
    echo "[$DATE] ALERT: High disk usage: ${DISK_USAGE}%" >> "$LOG_DIR/alerts.log"
fi

# Alert if swap usage is high
if (( $(echo "$SWAP_USAGE > 50" | bc -l) )); then
    echo "[$DATE] WARNING: Swap usage is high: ${SWAP_USAGE}%" >> "$LOG_DIR/alerts.log"
fi

# Keep only last 7 days of logs
find "$LOG_DIR" -name "*.log" -type f -mtime +7 -delete
