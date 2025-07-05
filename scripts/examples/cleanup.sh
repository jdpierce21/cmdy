#!/bin/bash
# System cleanup script example
set -e

# Colors
G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m' N='\033[0m'

echo -e "${B}🧹 Starting system cleanup...${N}"

# Function to show disk usage
show_disk_usage() {
    echo -e "${Y}📊 Current disk usage:${N}"
    df -h / | tail -1
    echo
}

# Show initial disk usage
show_disk_usage

# Clean package cache (adjust for your OS)
echo -e "${Y}🗑️  Cleaning package cache...${N}"
if command -v apt &> /dev/null; then
    # Debian/Ubuntu
    sudo apt autoremove -y 2>/dev/null || echo "Run with sudo for package cleanup"
    sudo apt autoclean 2>/dev/null || echo "Run with sudo for package cleanup"
elif command -v yum &> /dev/null; then
    # RedHat/CentOS
    sudo yum clean all 2>/dev/null || echo "Run with sudo for package cleanup"
elif command -v brew &> /dev/null; then
    # macOS
    brew cleanup
fi
echo -e "${G}✓ Package cache cleaned${N}"

# Clean temporary files
echo -e "${Y}🗑️  Cleaning temporary files...${N}"
# Clean /tmp (be careful!)
find /tmp -type f -atime +7 -delete 2>/dev/null || true
# Clean user temp directories
rm -rf ~/.cache/thumbnails/* 2>/dev/null || true
rm -rf ~/.local/share/Trash/* 2>/dev/null || true
echo -e "${G}✓ Temporary files cleaned${N}"

# Clean Docker (if installed)
if command -v docker &> /dev/null; then
    echo -e "${Y}🐳 Cleaning Docker...${N}"
    docker system prune -f 2>/dev/null || echo "Docker cleanup requires permissions"
    echo -e "${G}✓ Docker cleaned${N}"
fi

# Clean old log files
echo -e "${Y}📄 Cleaning old logs...${N}"
find /var/log -name "*.log" -type f -size +100M 2>/dev/null | head -5 | while read logfile; do
    echo "Large log file: $logfile ($(du -h "$logfile" | cut -f1))"
done
echo -e "${G}✓ Log analysis completed${N}"

# Show final disk usage
echo -e "${B}🎉 Cleanup completed!${N}"
show_disk_usage