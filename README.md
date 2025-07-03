# cmdy

A modern CLI command assistant for running OS-specific commands through an interactive menu.

## Features

- **Fast startup** - Single Go binary, no dependencies
- **Cross-platform** - Linux, macOS, Windows support
- **Config-driven** - Easy to customize via YAML
- **Modern UI** - Uses fzf for beautiful menus
- **OS-aware** - Automatically runs correct commands for your OS

## Installation

1. **Install Go** (if not already installed):
   ```bash
   # Ubuntu/Debian
   sudo apt install golang-go
   
   # macOS
   brew install go
   ```

2. **Install fzf**:
   ```bash
   # Ubuntu/Debian
   sudo apt install fzf
   
   # macOS
   brew install fzf
   ```

3. **Build the binary**:
   ```bash
   ./build.sh
   ```

## Usage

```bash
# Run the menu
./cmdy

# Or install globally
sudo mv cmdy /usr/local/bin/
cmdy
```

## Configuration

Edit `config.yaml` to add/modify menu options:

```yaml
menu_options:
  - shortcut: "1"
    name: "System Health"
    description: "Check system resources"
    commands:
      linux: "htop"
      mac: "top"
      
  - shortcut: "2"
    name: "Network Info"
    description: "Show network configuration"
    commands:
      linux: "ip addr show"
      mac: "ifconfig"
      
  # Custom scripts
  - shortcut: "6"
    name: "Database Backup"
    description: "Create database backup"
    commands:
      linux: "./scripts/backup.sh"
      mac: "./scripts/backup.sh"
```

## Custom Scripts

The `scripts/` directory is where you can add your own custom scripts:

1. **Add your script** to the `scripts/` directory
2. **Make it executable**: `chmod +x scripts/your-script.sh`
3. **Reference it in config.yaml** using relative paths

### Included Examples:
- `scripts/backup.sh` - Database backup with timestamps
- `scripts/deploy.sh` - Application deployment script
- `scripts/cleanup.sh` - System cleanup and maintenance
- `scripts/health-check.sh` - Detailed system health report

### Script Best Practices:
- Use `#!/bin/bash` or `#!/bin/sh` for shell scripts
- Add error handling with `set -e`
- Provide user feedback with colored output
- Accept arguments for flexibility
- Make scripts cross-platform when possible

## Why cmdy?

- **Instant startup** - Compiled Go binary, no interpreter overhead
- **Single binary** - No dependency management needed
- **Memory assistance** - Stop looking up commands constantly
- **OS-aware** - Same config works on Linux, macOS, Windows
- **Modern UX** - Beautiful fzf interface with fuzzy search
- **Config-driven** - Customize without touching code

## Development

```bash
# Run directly
go run main.go

# Build optimized binary
go build -ldflags="-s -w" -o cmdy main.go

# Install from source
go install github.com/jdpierce21/cmdy@latest
```