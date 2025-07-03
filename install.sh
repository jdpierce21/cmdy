#!/bin/bash

# cmdy installer script
# Usage: curl -sSL https://raw.githubusercontent.com/jdpierce21/cmdy/master/install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
REPO_URL="https://github.com/jdpierce21/cmdy"
REPO_RAW_URL="https://raw.githubusercontent.com/jdpierce21/cmdy/master"
INSTALL_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/cmdy"

echo -e "${BLUE}🚀 Installing cmdy - Modern CLI Command Assistant${NC}"
echo "Repository: $REPO_URL"
echo

# Function to detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "mac";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

# Function to install dependencies
install_dependencies() {
    local os=$(detect_os)
    
    echo -e "${YELLOW}📦 Checking dependencies...${NC}"
    
    # Check and install fzf
    if ! command -v fzf &> /dev/null; then
        echo -e "${YELLOW}Installing fzf...${NC}"
        case $os in
            "linux")
                if command -v apt &> /dev/null; then
                    sudo apt update && sudo apt install -y fzf
                elif command -v yum &> /dev/null; then
                    sudo yum install -y fzf
                elif command -v pacman &> /dev/null; then
                    sudo pacman -S fzf
                else
                    echo -e "${RED}❌ Cannot install fzf automatically. Please install manually.${NC}"
                    echo "Visit: https://github.com/junegunn/fzf#installation"
                    exit 1
                fi
                ;;
            "mac")
                if command -v brew &> /dev/null; then
                    brew install fzf
                else
                    echo -e "${RED}❌ Homebrew not found. Please install fzf manually.${NC}"
                    echo "Visit: https://github.com/junegunn/fzf#installation"
                    exit 1
                fi
                ;;
            *)
                echo -e "${RED}❌ Unsupported OS for automatic fzf installation.${NC}"
                echo "Please install fzf manually: https://github.com/junegunn/fzf#installation"
                exit 1
                ;;
        esac
        echo -e "${GREEN}✓ fzf installed${NC}"
    else
        echo -e "${GREEN}✓ fzf already installed${NC}"
    fi
    
    # Check and install Go (for building from source)
    if ! command -v go &> /dev/null; then
        echo -e "${YELLOW}Installing Go...${NC}"
        case $os in
            "linux")
                if command -v apt &> /dev/null; then
                    sudo apt update && sudo apt install -y golang-go
                elif command -v yum &> /dev/null; then
                    sudo yum install -y golang
                elif command -v pacman &> /dev/null; then
                    sudo pacman -S go
                else
                    echo -e "${RED}❌ Cannot install Go automatically. Please install manually.${NC}"
                    echo "Visit: https://golang.org/doc/install"
                    exit 1
                fi
                ;;
            "mac")
                if command -v brew &> /dev/null; then
                    brew install go
                else
                    echo -e "${RED}❌ Homebrew not found. Please install Go manually.${NC}"
                    echo "Visit: https://golang.org/doc/install"
                    exit 1
                fi
                ;;
            *)
                echo -e "${RED}❌ Unsupported OS for automatic Go installation.${NC}"
                echo "Please install Go manually: https://golang.org/doc/install"
                exit 1
                ;;
        esac
        echo -e "${GREEN}✓ Go installed${NC}"
    else
        echo -e "${GREEN}✓ Go already installed${NC}"
    fi
}

# Function to create directories
create_directories() {
    echo -e "${YELLOW}📁 Creating directories...${NC}"
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    echo -e "${GREEN}✓ Directories created${NC}"
}

# Function to download and build cmdy
install_cmdy() {
    echo -e "${YELLOW}🔨 Building cmdy from source...${NC}"
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Clone repository
    echo "Cloning repository..."
    git clone "$REPO_URL.git" . || {
        echo -e "${RED}❌ Failed to clone repository${NC}"
        exit 1
    }
    
    # Build binary
    echo "Building binary..."
    go build -o cmdy main.go || {
        echo -e "${RED}❌ Failed to build cmdy${NC}"
        exit 1
    }
    
    # Install binary (rename to .bin for wrapper)
    echo "Installing binary to $INSTALL_DIR..."
    mv cmdy "$INSTALL_DIR/cmdy.bin"
    chmod +x "$INSTALL_DIR/cmdy.bin"
    
    # Copy config and scripts
    echo "Installing configuration..."
    cp config.yaml "$CONFIG_DIR/"
    cp -r scripts "$CONFIG_DIR/"
    chmod +x "$CONFIG_DIR/scripts"/*.sh 2>/dev/null || true
    
    # Cleanup
    cd "$HOME"
    rm -rf "$TEMP_DIR"
    
    echo -e "${GREEN}✓ cmdy installed successfully${NC}"
}

# Function to setup PATH
setup_path() {
    echo -e "${YELLOW}🔧 Setting up PATH...${NC}"
    
    # Add to PATH in shell profile
    SHELL_RC=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        SHELL_RC="$HOME/.bashrc"
    fi
    
    if [[ -n "$SHELL_RC" ]] && [[ -f "$SHELL_RC" ]]; then
        if ! grep -q "$INSTALL_DIR" "$SHELL_RC"; then
            echo "" >> "$SHELL_RC"
            echo "# cmdy installer" >> "$SHELL_RC"
            echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_RC"
            echo -e "${GREEN}✓ Added $INSTALL_DIR to PATH in $SHELL_RC${NC}"
        else
            echo -e "${GREEN}✓ PATH already configured${NC}"
        fi
    fi
    
    # Export for current session
    export PATH="$INSTALL_DIR:$PATH"
}

# Function to create wrapper script
create_wrapper() {
    echo -e "${YELLOW}📝 Creating wrapper script...${NC}"
    
    # Create wrapper script (binary already renamed to .bin)
    cat > "$INSTALL_DIR/cmdy" << 'EOF'
#!/bin/bash

# cmdy wrapper script
CONFIG_DIR="$HOME/.config/cmdy"

# Change to config directory so relative paths work
cd "$CONFIG_DIR"

# Run the actual cmdy binary
exec "$HOME/.local/bin/cmdy.bin" "$@"
EOF

    chmod +x "$INSTALL_DIR/cmdy"
    
    echo -e "${GREEN}✓ Wrapper script created${NC}"
}

# Function to verify installation
verify_installation() {
    echo -e "${YELLOW}🔍 Verifying installation...${NC}"
    
    if command -v cmdy &> /dev/null; then
        echo -e "${GREEN}✓ cmdy is in PATH${NC}"
    else
        echo -e "${YELLOW}⚠️  cmdy not in PATH. You may need to restart your shell or run:${NC}"
        echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    fi
    
    if [[ -f "$CONFIG_DIR/config.yaml" ]]; then
        echo -e "${GREEN}✓ Configuration installed${NC}"
    else
        echo -e "${RED}❌ Configuration not found${NC}"
    fi
    
    if [[ -d "$CONFIG_DIR/scripts" ]]; then
        echo -e "${GREEN}✓ Example scripts installed${NC}"
    else
        echo -e "${RED}❌ Scripts not found${NC}"
    fi
}

# Main installation flow
main() {
    echo -e "${BLUE}Starting installation...${NC}"
    
    install_dependencies
    create_directories
    install_cmdy
    create_wrapper
    setup_path
    verify_installation
    
    echo
    echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
    echo
    echo -e "${BLUE}Usage:${NC}"
    echo "  cmdy                    # Run the interactive menu"
    echo "  cmdy --help             # Show help"
    echo
    echo -e "${BLUE}Configuration:${NC}"
    echo "  Config: $CONFIG_DIR/config.yaml"
    echo "  Scripts: $CONFIG_DIR/scripts/"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Restart your shell or run one of these:"
    echo "   source ~/.bashrc    # For bash"
    echo "   source ~/.zshrc     # For zsh"
    echo "   export PATH=\"$INSTALL_DIR:\$PATH\"  # For current session"
    echo "2. Run 'cmdy' to start using your command assistant!"
    echo "3. Customize $CONFIG_DIR/config.yaml to add your own commands"
    echo "4. Add custom scripts to $CONFIG_DIR/scripts/"
    echo
    echo -e "${BLUE}If 'cmdy' command not found:${NC}"
    echo "  $INSTALL_DIR/cmdy    # Run directly"
    echo
    echo -e "${YELLOW}⭐ Star the repo: $REPO_URL${NC}"
}

# Run main function
main "$@"