#!/bin/bash

# Detailed system health check script
# Usage: ./scripts/health-check.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🏥 System Health Check Report${NC}"
echo "Generated on: $(date)"
echo "Hostname: $(hostname)"
echo "=================================="

# CPU Usage
echo -e "\n${YELLOW}💻 CPU Information:${NC}"
if command -v lscpu &> /dev/null; then
    echo "CPU Model: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
    echo "CPU Cores: $(nproc)"
fi
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"

# Memory Usage
echo -e "\n${YELLOW}🧠 Memory Usage:${NC}"
if command -v free &> /dev/null; then
    free -h
else
    # macOS alternative
    echo "Memory info not available (install free command)"
fi

# Disk Usage
echo -e "\n${YELLOW}💾 Disk Usage:${NC}"
df -h | grep -E "^/dev|^tmpfs" | awk '{print $1 "\t" $3 "/" $2 " (" $5 ")"}'

# Network Status
echo -e "\n${YELLOW}🌐 Network Status:${NC}"
if command -v ping &> /dev/null; then
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo -e "${GREEN}✓ Internet connectivity: OK${NC}"
    else
        echo -e "${RED}✗ Internet connectivity: FAILED${NC}"
    fi
fi

# Running Services (systemd)
if command -v systemctl &> /dev/null; then
    echo -e "\n${YELLOW}⚙️  System Services:${NC}"
    echo "Failed services:"
    systemctl --failed --no-legend | head -5 || echo "No failed services"
fi

# Uptime
echo -e "\n${YELLOW}⏰ System Uptime:${NC}"
uptime

# Recent logins (if available)
if command -v last &> /dev/null; then
    echo -e "\n${YELLOW}👥 Recent Logins:${NC}"
    last -n 5 2>/dev/null || echo "Login history not available"
fi

# Check for updates (Ubuntu/Debian)
if command -v apt &> /dev/null; then
    echo -e "\n${YELLOW}📦 Available Updates:${NC}"
    apt list --upgradable 2>/dev/null | wc -l | xargs echo "Packages ready for update:"
fi

echo -e "\n${GREEN}🎉 Health check completed!${NC}"