```
  ██████╗ ███╗   ███╗ ██████╗  ██╗   ██╗
 ██╔════╝ ████╗ ████║ ██╔══██╗ ╚██╗ ██╔╝
 ██║      ██╔████╔██║ ██║  ██║  ╚████╔╝ 
 ██║      ██║╚██╔╝██║ ██║  ██║   ╚██╔╝  
 ╚██████╗ ██║ ╚═╝ ██║ ██████╔╝    ██║   
  ╚═════╝ ╚═╝     ╚═╝ ╚═════╝     ╚═╝   
```

# cmdy

A modern CLI command assistant for running OS-specific commands through an interactive menu.

## Features

- **⚡ Lightning fast** - Optimized Go binary with minimal overhead
- **🌍 Cross-platform** - Linux, macOS, Windows support
- **📝 Simple config** - Clean YAML format, no complex syntax
- **🎨 Modern UI** - Beautiful fzf interface with fuzzy search
- **🔄 OS-aware** - Automatically runs correct commands for your OS
- **🚀 Zero dependencies** - Single binary, no runtime requirements

## Installation

### 🚀 Quick Install (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/jdpierce21/cmdy/master/install.sh | bash
```

This one-liner will automatically:
- ✅ Install dependencies (fzf, Go)
- ✅ Build cmdy from source  
- ✅ Install to `~/.local/bin/cmdy`
- ✅ Set up configuration in `~/.config/cmdy/`
- ✅ Add to your PATH

### 🔧 Manual Installation

1. **Install dependencies**:
   ```bash
   # Ubuntu/Debian
   sudo apt install golang-go fzf
   
   # macOS
   brew install go fzf
   ```

2. **Clone and build**:
   ```bash
   git clone https://github.com/jdpierce21/cmdy.git
   cd cmdy
   ./build.sh
   ```

3. **Install globally** (optional):
   ```bash
   sudo mv cmdy /usr/local/bin/
   ```

## Usage

```bash
# Run locally
./cmdy

# Or install globally and run
sudo mv cmdy /usr/local/bin/
cmdy
```

### Navigation

- Use **arrow keys** or **type to search** (fuzzy matching)
- Press **Enter** to execute selected command
- Press **Ctrl+C** or **Escape** to exit
- Commands run in your current shell environment

## Configuration

Edit `config.yaml` to add/modify menu options. Each option has a `display` field (what appears in the menu) and OS-specific `commands`:

```yaml
menu_options:
  - display: "System Health - Check system resources"
    commands:
      linux: "htop"
      mac: "top"
      
  - display: "Network Info - Show network configuration"
    commands:
      linux: "ip addr show"
      mac: "ifconfig"
      
  # Custom scripts
  - display: "Database Backup - Create database backup"
    commands:
      linux: "./scripts/backup.sh"
      mac: "./scripts/backup.sh"
```

### Configuration Format

- **`display`** - Text shown in the fzf menu (can be any descriptive text)
- **`commands`** - Map of OS-specific commands to run
  - Supported OS keys: `linux`, `mac`, `windows`
  - Use `darwin` instead of `mac` if needed (automatically mapped)

### Menu Navigation

- **Arrow keys** or **fuzzy search** to navigate
- **Enter** to select and execute
- **Ctrl+C** or **Escape** to exit
- No need for explicit quit options - built into fzf

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

- **⚡ Instant startup** - Highly optimized Go binary (<100 lines of code)
- **📦 Single binary** - No dependency management or runtime requirements
- **🧠 Memory assistance** - Stop looking up commands constantly
- **🌐 OS-aware** - Same config works across all platforms
- **🎯 Modern UX** - Intuitive fzf interface with fuzzy search
- **⚙️ Config-driven** - Customize without touching code
- **🔧 Lean & Fast** - Minimal memory footprint, maximum performance

## Development

```bash
# Run directly
go run main.go

# Build optimized binary
go build -ldflags="-s -w" -o cmdy main.go

# Install from source
go install github.com/jdpierce21/cmdy@latest
```