#!/bin/bash

# cmdy installer script
# Usage: curl -sSL https://raw.githubusercontent.com/jdpierce21/cmdy/master/install.sh | bash

set -e

# Colors for output (can be overridden by environment variables)
RED="${CMDY_COLOR_RED:-\033[0;31m}"
GREEN="${CMDY_COLOR_GREEN:-\033[0;32m}"
YELLOW="${CMDY_COLOR_YELLOW:-\033[1;33m}"
BLUE="${CMDY_COLOR_BLUE:-\033[0;34m}"
NC="${CMDY_COLOR_RESET:-\033[0m}"

# Configuration (can be overridden by environment variables)
REPO_URL="${CMDY_REPO_URL:-https://github.com/jdpierce21/cmdy}"
REPO_RAW_URL="${CMDY_REPO_RAW_URL:-https://raw.githubusercontent.com/jdpierce21/cmdy/master}"
INSTALL_DIR="${CMDY_INSTALL_DIR:-$HOME/.local/bin}"
CONFIG_DIR="${CMDY_CONFIG_DIR:-$HOME/.config/cmdy}"

# Show branding
echo -e "${BLUE}"
echo "  ██████╗ ███╗   ███╗ ██████╗  ██╗   ██╗"
echo " ██╔════╝ ████╗ ████║ ██╔══██╗ ╚██╗ ██╔╝"
echo " ██║      ██╔████╔██║ ██║  ██║  ╚████╔╝ "
echo " ██║      ██║╚██╔╝██║ ██║  ██║   ╚██╔╝  "
echo " ╚██████╗ ██║ ╚═╝ ██║ ██████╔╝    ██║   "
echo "  ╚═════╝ ╚═╝     ╚═╝ ╚═════╝     ╚═╝   "
echo -e "${NC}"
echo -e "${BLUE}${CMDY_INSTALL_MESSAGE:-🚀 Installing cmdy}${NC}"


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
    
    # Check and install fzf
    if ! command -v fzf &> /dev/null; then
        case $os in
            "linux")
                if command -v apt &> /dev/null; then
                    sudo apt update &> /dev/null && sudo apt install -y fzf &> /dev/null
                elif command -v yum &> /dev/null; then
                    sudo yum install -y fzf &> /dev/null
                elif command -v pacman &> /dev/null; then
                    sudo pacman -S fzf &> /dev/null
                else
                    echo -e "${RED}❌ Cannot install fzf automatically. Please install manually.${NC}"
                    echo "Visit: ${CMDY_FZF_INSTALL_URL:-https://github.com/junegunn/fzf#installation}"
                    exit 1
                fi
                ;;
            "mac")
                if command -v brew &> /dev/null; then
                    brew install fzf &> /dev/null
                else
                    echo -e "${RED}❌ Homebrew not found. Please install fzf manually.${NC}"
                    echo "Visit: ${CMDY_FZF_INSTALL_URL:-https://github.com/junegunn/fzf#installation}"
                    exit 1
                fi
                ;;
            *)
                echo -e "${RED}❌ Unsupported OS for automatic fzf installation.${NC}"
                echo "Please install fzf manually: ${CMDY_FZF_INSTALL_URL:-https://github.com/junegunn/fzf#installation}"
                exit 1
                ;;
        esac
    fi
    
    # Check and install Go (for building from source)
    if ! command -v go &> /dev/null; then
        case $os in
            "linux")
                if command -v apt &> /dev/null; then
                    sudo apt update &> /dev/null && sudo apt install -y golang-go &> /dev/null
                elif command -v yum &> /dev/null; then
                    sudo yum install -y golang &> /dev/null
                elif command -v pacman &> /dev/null; then
                    sudo pacman -S go &> /dev/null
                else
                    echo -e "${RED}❌ Cannot install Go automatically. Please install manually.${NC}"
                    echo "Visit: ${CMDY_GO_INSTALL_URL:-https://golang.org/doc/install}"
                    exit 1
                fi
                ;;
            "mac")
                if command -v brew &> /dev/null; then
                    brew install go &> /dev/null
                else
                    echo -e "${RED}❌ Homebrew not found. Please install Go manually.${NC}"
                    echo "Visit: ${CMDY_GO_INSTALL_URL:-https://golang.org/doc/install}"
                    exit 1
                fi
                ;;
            *)
                echo -e "${RED}❌ Unsupported OS for automatic Go installation.${NC}"
                echo "Please install Go manually: ${CMDY_GO_INSTALL_URL:-https://golang.org/doc/install}"
                exit 1
                ;;
        esac
    fi
}

# Function to create directories
create_directories() {
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
}

# Function to download and build cmdy
install_cmdy() {
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Clone repository
    git clone "$REPO_URL.git" . &> /dev/null || {
        echo -e "${RED}❌ Failed to clone repository${NC}"
        exit 1
    }
    
    # Build binary
    go build -o cmdy ${CMDY_MAIN_FILE:-main.go} &> /dev/null || {
        echo -e "${RED}❌ Failed to build cmdy${NC}"
        exit 1
    }
    
    # Install binary (rename to .bin for wrapper)
    
    if [[ -f "cmdy" ]]; then
        mv cmdy "$INSTALL_DIR/${CMDY_BINARY_TEMP:-cmdy.bin}" || {
            echo -e "${RED}❌ Failed to move binary${NC}"
            exit 1
        }
        chmod +x "$INSTALL_DIR/${CMDY_BINARY_TEMP:-cmdy.bin}"
    else
        echo -e "${RED}❌ Binary not found after build${NC}"
        exit 1
    fi
    
    # Copy config and scripts
    
    # Only copy config if it doesn't exist (preserve user customizations)
    if [[ ! -f "$CONFIG_DIR/${CMDY_CONFIG_FILE:-config.yaml}" ]]; then
        cp config.yaml "$CONFIG_DIR/"
    else
        cp config.yaml "$CONFIG_DIR/${CMDY_CONFIG_BACKUP:-config.yaml.new}" &> /dev/null
    fi
    
    # Create layered script structure
    
    # Create directory structure
    mkdir -p "$CONFIG_DIR/${CMDY_SCRIPTS_EXAMPLES:-scripts/examples}"
    mkdir -p "$CONFIG_DIR/${CMDY_SCRIPTS_USER:-scripts/user}"
    
    # Always update example scripts
    cp scripts/*.sh "$CONFIG_DIR/${CMDY_SCRIPTS_EXAMPLES:-scripts/examples}/" &> /dev/null || true
    chmod +x "$CONFIG_DIR/${CMDY_SCRIPTS_EXAMPLES:-scripts/examples}/"*.sh &> /dev/null || true
    
    # Migrate existing user scripts if any
    if [[ -d "$CONFIG_DIR/${CMDY_SCRIPTS_LEGACY:-scripts}" ]] && [[ ! -d "$CONFIG_DIR/${CMDY_SCRIPTS_EXAMPLES:-scripts/examples}" ]]; then
        find "$CONFIG_DIR/${CMDY_SCRIPTS_LEGACY:-scripts}" -name "*.sh" -maxdepth 1 -exec mv {} "$CONFIG_DIR/${CMDY_SCRIPTS_USER:-scripts/user}/" \; &> /dev/null
    fi
    
    # Create helpful README
    cat > "$CONFIG_DIR/${CMDY_SCRIPTS_LEGACY:-scripts}/README.md" << 'EOF'
# Scripts Directory Structure

## examples/
Stock scripts provided by cmdy. These are updated automatically.
Copy to user/ directory and modify as needed.

**These files are overwritten during updates!**

## user/
Your custom scripts. These are never overwritten.
Add your own scripts here or copy/modify from examples/.

## Usage
1. Browse examples: `ls ~/.config/cmdy/scripts/examples/`
2. Copy to customize: `cp examples/backup.sh user/my-backup.sh`
3. Make executable: `chmod +x user/my-backup.sh`
4. Run cmdy - your script appears automatically!
EOF
    
    
    # Cleanup
    cd "$HOME"
    rm -rf "$TEMP_DIR"
    
}

# Function to setup PATH
setup_path() {
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
        fi
    fi
    
    # Export for current session
    export PATH="$INSTALL_DIR:$PATH"
}

# Function to create wrapper script
create_wrapper() {
    
    # Create wrapper script (binary already renamed to .bin)
    cat > "$INSTALL_DIR/${CMDY_BINARY_NAME:-cmdy}" << EOF
#!/bin/bash

# cmdy wrapper script
CONFIG_DIR="\${CMDY_CONFIG_DIR:-\$HOME/.config/cmdy}"

# Change to config directory so relative paths work
cd "\$CONFIG_DIR"

# Run the actual cmdy binary
exec "\${CMDY_INSTALL_DIR:-\$HOME/.local/bin}/\${CMDY_BINARY_TEMP:-cmdy.bin}" "\$@"
EOF

    # Check if wrapper was created successfully
    if [[ -f "$INSTALL_DIR/${CMDY_BINARY_NAME:-cmdy}" ]]; then
        chmod +x "$INSTALL_DIR/${CMDY_BINARY_NAME:-cmdy}"
    else
        echo -e "${RED}❌ Failed to create wrapper script${NC}"
        exit 1
    fi
}

# Function to verify installation
verify_installation() {
    if ! command -v cmdy &> /dev/null; then
        echo -e "${RED}❌ Installation failed - cmdy not found${NC}"
        exit 1
    fi
    
    if [[ ! -f "$CONFIG_DIR/${CMDY_CONFIG_FILE:-config.yaml}" ]]; then
        echo -e "${RED}❌ Configuration not found${NC}"
        exit 1
    fi
    
    if [[ ! -d "$CONFIG_DIR/scripts" ]]; then
        echo -e "${RED}❌ Scripts not found${NC}"
        exit 1
    fi
}

# Main installation flow
main() {
    
    install_dependencies
    create_directories
    install_cmdy
    create_wrapper
    setup_path
    verify_installation
    
    echo -e "${GREEN}${CMDY_SUCCESS_INSTALL:-✓ Installed}${NC}"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "• Run '${CMDY_BINARY_NAME:-cmdy}' to start"
    echo "• Add scripts to ${CONFIG_DIR}/${CMDY_SCRIPTS_USER:-scripts/user}/"
    echo "• Edit ${CONFIG_DIR}/${CMDY_CONFIG_FILE:-config.yaml} to customize"
}

# Run main function
main "$@"