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

echo -e "\n${BLUE}🚀 Installing cmdy ... ${NC}\n"

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
    local fail=0
    # Check and install fzf
    if ! command -v fzf &> /dev/null; then
        case $os in
            "linux")
                if command -v apt &> /dev/null; then
                    sudo apt update && sudo apt install -y fzf || fail=1
                elif command -v yum &> /dev/null; then
                    sudo yum install -y fzf || fail=1
                elif command -v pacman &> /dev/null; then
                    sudo pacman -S fzf || fail=1
                else
                    fail=1
                fi
                ;;
            "mac")
                if command -v brew &> /dev/null; then
                    brew install fzf || fail=1
                else
                    fail=1
                fi
                ;;
            *)
                fail=1
                ;;
        esac
        if [[ $fail -eq 1 ]] || ! command -v fzf &> /dev/null; then
            echo -e "${RED}📦 Checking dependencies... ❌ Failed to install required tools${NC}"
            exit 1
        fi
    fi
    # Check and install Go (for building from source)
    if ! command -v go &> /dev/null; then
        case $os in
            "linux")
                if command -v apt &> /dev/null; then
                    sudo apt update && sudo apt install -y golang-go || fail=1
                elif command -v yum &> /dev/null; then
                    sudo yum install -y golang || fail=1
                elif command -v pacman &> /dev/null; then
                    sudo pacman -S go || fail=1
                else
                    fail=1
                fi
                ;;
            "mac")
                if command -v brew &> /dev/null; then
                    brew install go || fail=1
                else
                    fail=1
                fi
                ;;
            *)
                fail=1
                ;;
        esac
        if [[ $fail -eq 1 ]] || ! command -v go &> /dev/null; then
            echo -e "📦 Checking dependencies... ❌ ${RC}${RED} Failed to install required tools${NC}"
            exit 1
        fi
    fi
    echo -e "📦 Checking dependencies... ✅"
}

# Function to create directories
create_directories() {
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    echo -e "📁 Creating directories... ✅"
}

# Function to download and build cmdy
install_cmdy() {
    local status="🔨 Building cmdy from source..."
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    # Clone repository
    git clone "$REPO_URL.git" . > /dev/null 2>&1 || {
        echo -e "${RED}${status} ❌ Failed to build or install cmdy${NC}"
        exit 1
    }
    # Build binary
    go build -o cmdy > /dev/null 2>&1 || {
        echo -e "${RED}${status} ❌ Failed to build or install cmdy${NC}"
        exit 1
    }
    # Install binary (rename to .bin for wrapper)
    if [[ -f "cmdy" ]]; then
        mv cmdy "$INSTALL_DIR/cmdy.bin" > /dev/null 2>&1 || {
            echo -e "${RED}${status} ❌ Failed to build or install cmdy${NC}"
            exit 1
        }
        chmod +x "$INSTALL_DIR/cmdy.bin"
    else
        echo -e "${RED}${status} ❌ Failed to build or install cmdy${NC}"
        exit 1
    fi
    # Copy config and scripts
    cp config.yaml "$CONFIG_DIR/" > /dev/null 2>&1
    cp -r scripts "$CONFIG_DIR/" > /dev/null 2>&1
    chmod +x "$CONFIG_DIR/scripts"/*.sh 2>/dev/null || true
    # Cleanup
    cd "$HOME"
    rm -rf "$TEMP_DIR"
    echo -e "🔨 Building cmdy from source... ✅${NC}"
}

# Function to setup PATH
setup_path() {
    local fail=0
    IS_FISH=false

    # Add to PATH in shell profile
    SHELL_RC=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        SHELL_RC="$HOME/.bashrc"
    elif [[ "$SHELL" == *"fish"* ]]; then
        SHELL_RC="$HOME/.config/fish/config.fish"
        IS_FISH=true
    fi

    if [[ -n "$SHELL_RC" ]]; then
        if [[ ! -f "$SHELL_RC" ]]; then
            # Offer to create shell profile if it doesn't exist
            echo -e "${YELLOW}$SHELL_RC does not exist.${NC}"
            echo -n "Create it to make cmdy available in new shells? (y/n) [y]: "
            read -r response
            response=${response:-y}

            if [[ "$response" =~ ^[Yy]$ ]]; then
                touch "$SHELL_RC"
            else
                echo -e "${YELLOW}⚠️  Skipped creating $SHELL_RC${NC}"
                echo -e "${YELLOW}⚠️  You may need to add $INSTALL_DIR to your PATH manually${NC}"
                fail=1
            fi
        fi

        if [[ -f "$SHELL_RC" ]] && ! grep -q "$INSTALL_DIR" "$SHELL_RC"; then
            {
                echo ""
                echo "# cmdy installer"
                if [ "$IS_FISH" = true ]; then
                    echo "set -Ux PATH $INSTALL_DIR \$PATH"
                else
                    echo "export PATH=\"$INSTALL_DIR:\$PATH\""
                fi
            } >> "$SHELL_RC" || fail=1

            # Source the shell profile to make cmdy available immediately
            if [[ "$SHELL" == *"zsh"* ]]; then
                source "$HOME/.zshrc" 2>/dev/null || true
            elif [[ "$SHELL" == *"bash"* ]]; then
                source "$HOME/.bashrc" 2>/dev/null || true
            fi
            # If append failed, fail=1 is already set
        fi
    else
        echo -e "${YELLOW}⚠️  Unknown shell, PATH not automatically configured${NC}"
        fail=1
    fi

    if [ "$IS_FISH" = false ]; then
        export PATH="$INSTALL_DIR:$PATH"
    fi

    if [[ $fail -eq 0 ]]; then
        echo -e "🔧 Setting up PATH... ✅"
    elif [[ -n "$SHELL_RC" ]]; then
        echo -e "${YELLOW}🔧 Setting up PATH... ⚠️ PATH may not be updated for new shells${NC}"
    else
        echo -e "${RED}🔧 Setting up PATH... ❌ Could not determine or modify shell rc file${NC}"
    fi
}

# Function to create wrapper script
create_wrapper() {
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

    # Check if wrapper was created successfully
    if [[ -f "$INSTALL_DIR/cmdy" ]]; then
        chmod +x "$INSTALL_DIR/cmdy"
        echo -e "📝 Creating wrapper script... ✅"
    else
        echo -e "${RED}📝 Creating wrapper script... ❌ Failed to create wrapper${NC}"
        exit 1
    fi
}

# Function to verify installation
verify_installation() {
    local fail=0
    if ! command -v cmdy &> /dev/null; then
        fail=1
    fi
    if [[ ! -f "$CONFIG_DIR/config.yaml" ]]; then
        fail=1
    fi
    if [[ ! -d "$CONFIG_DIR/scripts" ]]; then
        fail=1
    fi
    if [[ $fail -eq 0 ]]; then
        echo -e "🔍 Verifying installation... ✅"
    else
        echo -e "${RED}🔍 Verifying installation... ❌ One or more checks failed${NC}"
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

    echo
    echo -e "🎉🎉🎉 Installation completed successfully! 🎉🎉🎉"
    echo
    echo -e "${BLUE}Usage:${NC}"
    echo "  cmdy                    # Run the interactive menu"
    echo "  cmdy --help             # Show help"
    echo
    echo -e "${BLUE}Customization files:${NC}"
    echo "  Config: $CONFIG_DIR/config.yaml"
    echo "  Scripts: $CONFIG_DIR/scripts/"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Run 'cmdy' to start using your command assistant!"
    echo "2. Customize $CONFIG_DIR/config.yaml to add your own commands"
    echo "3. Add custom scripts to $CONFIG_DIR/scripts/"
    echo
    echo -e "${BLUE}If 'cmdy' command not found:${NC}"
    echo "  $INSTALL_DIR/cmdy    # Run directly"
    echo
    echo -e "${YELLOW}⭐ Star the repo: $REPO_URL${NC}"
}

# Run main function
main "$@"