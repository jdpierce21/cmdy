# Custom Scripts Directory

This directory is where you can add your own custom scripts that cmdy can execute.

## 🎆 **NEW: Auto-Discovery!**

cmdy now automatically discovers and adds executable scripts to your menu!

### Super Simple Usage:

1. **Add your script** to this directory
2. **Make it executable**: `chmod +x scripts/your-script.sh`  
3. **Run cmdy** - your script appears automatically! ✨

### Optional Manual Configuration:

You can still manually configure scripts in `config.yaml` for custom display names:

```yaml
- display: "My Custom Script - Does something awesome"
  commands:
    linux: "./scripts/your-script.sh"
    mac: "./scripts/your-script.sh"
```

**Manual entries take precedence over auto-discovered scripts.**

## Examples included:

- `backup.sh` - Database backup script
- `deploy.sh` - Application deployment
- `cleanup.sh` - System cleanup tasks
- `health-check.sh` - Detailed system health

## 🔄 **Smart Deduplication**

- Auto-discovered scripts won't duplicate manual config entries
- cmdy shows you what was found: `"Auto-discovered 4 scripts, deduplicated 2"`
- Clean, organized menu with no duplicates

## Tips:

- **Just drop files and go** - No config needed for basic scripts
- Scripts should be **cross-platform** when possible
- Use **#!/bin/bash** or **#!/bin/sh** for shell scripts
- Add **error handling** and **user feedback**
- **Transparent**: cmdy tells you what scripts were found
- File names become menu entries (extension removed)