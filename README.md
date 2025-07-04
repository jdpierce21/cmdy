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
- **🔍 Auto-discovery** - Automatically finds executable scripts
- **🛠️ Self-managing** - Updates and maintains itself
- **🔒 Config preservation** - Never overwrites your customizations
- **💬 Transparent** - Clear feedback and helpful error messages

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

### Interactive Menu
```bash
# Run the interactive menu
cmdy
```

### Self-Management Commands
```bash
cmdy build         # Build the binary
cmdy install       # Install/update globally  
cmdy dev [msg]     # Full development workflow (commit + push + install)
cmdy update        # Pull latest changes and rebuild
cmdy version       # Show current version (git commit)
cmdy config        # Edit configuration file
cmdy help          # Show all commands
```

### Navigation

- Use **arrow keys** or **type to search** (fuzzy matching)
- Press **Enter** to execute selected command
- Press **Ctrl+C** or **Escape** to exit
- Commands run in your current shell environment

## Configuration

### Automatic Script Discovery

cmdy automatically discovers executable scripts in the `scripts/` directory! Just:

1. **Add your script** to the `scripts/` directory
2. **Make it executable**: `chmod +x scripts/your-script.sh`
3. **Run cmdy** - your script appears automatically!

### Manual Configuration

Edit `config.yaml` for custom menu entries or to override auto-discovered scripts:

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
      
  # Custom scripts (optional - auto-discovered if executable)
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

### Smart Deduplication

- Scripts in `config.yaml` take precedence over auto-discovered
- No duplicate entries - cmdy handles this automatically
- See discovery stats when running: `"Auto-discovered 4 scripts, deduplicated 2"`

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

## Self-Management Workflow

### For Developers
```bash
# Make changes to cmdy
vim main.go

# One command does everything:
cmdy dev "add awesome feature"
# ✓ Stages all changes
# ✓ Commits with your message  
# ✓ Pushes to GitHub
# ✓ Builds and installs globally
# ✓ Ready to use immediately!
```

### For Users
```bash
# Get latest version
cmdy update

# Configure your preferences  
cmdy config

# Check current version
cmdy version
```

## Why cmdy?

- **⚡ Instant startup** - Highly optimized Go binary
- **📦 Single binary** - No dependency management or runtime requirements
- **🧠 Memory assistance** - Stop looking up commands constantly
- **🌐 OS-aware** - Same config works across all platforms
- **🎯 Modern UX** - Intuitive fzf interface with fuzzy search
- **⚙️ Config-driven** - Customize without touching code
- **🔧 Lean & Fast** - Minimal memory footprint, maximum performance
- **🤖 Self-managing** - Updates and maintains itself
- **💬 Transparent** - Always tells you what's happening

## Troubleshooting

### Common Issues

**"No menu options available"**
```bash
# Solutions:
1. Add entries to config.yaml
2. Add executable scripts to scripts/ directory  
3. Check example: https://github.com/jdpierce21/cmdy
```

**"cmdy: command not found"**
```bash
# Add to PATH:
export PATH="$HOME/.local/bin:$PATH"

# Or run directly:
~/.local/bin/cmdy
```

**"Could not find cmdy source directory"**
```bash
# Options for updating:
1. cd /path/to/cmdy && cmdy update
2. curl -sSL install.sh | bash  # Safest
3. git clone repo && cmdy install
```

**"No suitable editor found"**
```bash
# Set your preferred editor:
export EDITOR=vim

# Or install a basic editor:
sudo apt install nano  # Ubuntu/Debian
brew install nano       # macOS
```

**Config file issues**
- cmdy preserves your custom config during updates
- New defaults are saved as `config.yaml.new` for reference
- Check YAML syntax if parsing fails

### Getting Help

- Run `cmdy help` for command overview
- Check verbose output - cmdy tells you what's happening
- All errors include specific solutions

## Development

### Quick Start
```bash
# Clone and build
git clone https://github.com/jdpierce21/cmdy.git
cd cmdy
cmdy build

# Development workflow
cmdy dev "your commit message"
```

### Manual Commands
```bash
# Run directly
go run main.go

# Build optimized binary
go build -ldflags="-s -w" -o cmdy main.go

# Install from source
go install github.com/jdpierce21/cmdy@latest
```