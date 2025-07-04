#!/bin/bash
# System cleanup script example
set -e

# Colors
G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m' N='\033[0m'

echo -e "${BLUE}🧹 Starting system cleanup...${NC}"

# Function to show disk usage
show_disk_usage() {
    echo -e "${YELLOW}📊 Current disk usage:${NC}"
    df -h / | tail -1
    echo
}

# Show initial disk usage
show_disk_usage

# Clean package cache (adjust for your OS)
echo -e "${YELLOW}🗑️  Cleaning package cache...${NC}"
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
echo -e "${GREEN}✓ Package cache cleaned${NC}"

# Clean temporary files
echo -e "${YELLOW}🗑️  Cleaning temporary files...${NC}"
# Clean /tmp (be careful!)
find /tmp -type f -atime +7 -delete 2>/dev/null || true
# Clean user temp directories
rm -rf ~/.cache/thumbnails/* 2>/dev/null || true
rm -rf ~/.local/share/Trash/* 2>/dev/null || true
echo -e "${GREEN}✓ Temporary files cleaned${NC}"

# Clean Docker (if installed)
if command -v docker &> /dev/null; then
    echo -e "${YELLOW}🐳 Cleaning Docker...${NC}"
    docker system prune -f 2>/dev/null || echo "Docker cleanup requires permissions"
    echo -e "${GREEN}✓ Docker cleaned${NC}"
fi

# Clean old log files
echo -e "${YELLOW}📄 Cleaning old logs...${NC}"
find /var/log -name "*.log" -type f -size +100M 2>/dev/null | head -5 | while read logfile; do
    echo "Large log file: $logfile ($(du -h "$logfile" | cut -f1))"
done
echo -e "${GREEN}✓ Log analysis completed${NC}"

# Show final disk usage
echo -e "${BLUE}🎉 Cleanup completed!${NC}"
show_disk_usage