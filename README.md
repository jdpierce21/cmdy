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
      darwin: "top"
      
  - shortcut: "2"
    name: "Network Info"
    description: "Show network configuration"
    commands:
      linux: "ip addr show"
      darwin: "ifconfig"
```

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