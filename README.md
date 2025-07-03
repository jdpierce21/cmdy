# Assist - Go Version

A modern CLI assistant tool for running OS-specific commands through an interactive menu.

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
./assist

# Or install globally
sudo mv assist /usr/local/bin/
assist
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

## Benefits over Python version

- **Instant startup** - No Python/Poetry overhead
- **Single binary** - No dependency management
- **Smaller size** - ~5MB vs Python + deps
- **Cross-platform** - One binary works everywhere
- **Native performance** - Compiled code

## Development

```bash
# Run directly
go run main.go

# Build optimized binary
go build -ldflags="-s -w" -o assist main.go
```