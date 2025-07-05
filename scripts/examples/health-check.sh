#!/bin/bash
# Detailed system health check script
set -e

# Colors
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m' N='\033[0m'

echo -e "${B}🏥 System Health Check Report${N}"
echo "Generated on: $(date)"
echo "Hostname: $(hostname)"
echo "=================================="

# CPU Usage
echo -e "\n${Y}💻 CPU Information:${N}"
if command -v lscpu &> /dev/null; then
    echo "CPU Model: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
    echo "CPU Cores: $(nproc)"
fi
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"

# Memory Usage
echo -e "\n${Y}🧠 Memory Usage:${N}"
if command -v free &> /dev/null; then
    free -h
else
    # macOS alternative
    echo "Memory info not available (install free command)"
fi

# Disk Usage
echo -e "\n${Y}💾 Disk Usage:${N}"
df -h | grep -E "^/dev|^tmpfs" | awk '{print $1 "\t" $3 "/" $2 " (" $5 ")"}'

# Network Status
echo -e "\n${Y}🌐 Network Status:${N}"
if command -v ping &> /dev/null; then
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo -e "${G}✓ Internet connectivity: OK${N}"
    else
        echo -e "${R}✗ Internet connectivity: FAILED${N}"
    fi
fi

# Running Services (systemd)
if command -v systemctl &> /dev/null; then
    echo -e "\n${Y}⚙️  System Services:${N}"
    echo "Failed services:"
    systemctl --failed --no-legend | head -5 || echo "No failed services"
fi

# Uptime
echo -e "\n${Y}⏰ System Uptime:${N}"
uptime

# Recent logins (if available)
if command -v last &> /dev/null; then
    echo -e "\n${Y}👥 Recent Logins:${N}"
    last -n 5 2>/dev/null || echo "Login history not available"
fi

# Check for updates (Ubuntu/Debian)
if command -v apt &> /dev/null; then
    echo -e "\n${Y}📦 Available Updates:${N}"
    apt list --upgradable 2>/dev/null | wc -l | xargs echo "Packages ready for update:"
fi

echo -e "\n${G}🎉 Health check completed!${N}"