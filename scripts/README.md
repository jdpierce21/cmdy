# Layered Scripts Directory 📁

## 🏗️ **NEW: Layered Structure!**

### 📂 **examples/** 
**Stock scripts provided by cmdy**
- ⚠️ **Updated automatically** - Don't edit these!
- 📋 Copy to `user/` directory to customize
- 📚 Learning resources and templates

### 👤 **user/**
**Your custom scripts**  
- 🔒 **Never overwritten** - Safe to edit
- 🎆 **Auto-discovered** - Just drop files and go!
- 🛠️ Your personal automation toolkit

## 🚀 **Quick Start:**

### For New Scripts:
```bash
# Add your script to user directory
cp my-script.sh scripts/user/
chmod +x scripts/user/my-script.sh
# Run cmdy - appears automatically!
```

### For Customizing Examples:
```bash
# Copy an example to customize
cp scripts/examples/backup.sh scripts/user/my-backup.sh
chmod +x scripts/user/my-backup.sh
# Edit scripts/user/my-backup.sh safely
```

### Advanced Configuration:
```yaml
# Optional: Override display name in config.yaml
- display: "My Custom Backup - Does awesome backups"
  commands:
    linux: "./scripts/user/my-backup.sh"
    mac: "./scripts/user/my-backup.sh"
```

## 📚 **Example Scripts Included:**

### In `examples/` directory:
- `backup.sh` - Database backup with timestamps
- `deploy.sh` - Application deployment to environments  
- `cleanup.sh` - System cleanup and maintenance
- `health-check.sh` - Comprehensive system health report

## 🎨 **Menu Display:**

- **[example] script-name** - From examples/ directory
- **[user] script-name** - From user/ directory  
- **script-name** - From legacy scripts/ (backward compatibility)

## 🔄 **Smart Features:**

- **Auto-discovery** - Executable scripts appear automatically
- **Smart deduplication** - No duplicate menu entries
- **Clear ownership** - Always know what's yours vs examples
- **Safe updates** - Your scripts never get overwritten
- **Transparent feedback** - See what was discovered

## 💡 **Pro Tips:**

- **Start with examples** - Copy and modify rather than starting from scratch
- **Use clear names** - File names become menu entries (minus extension)
- **Make executable** - `chmod +x` or scripts won't appear
- **Cross-platform** - Use `#!/bin/bash` for compatibility
- **Add error handling** - Use `set -e` and provide user feedback
- **Version control** - Keep your user/ scripts in git for backup