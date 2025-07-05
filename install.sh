#!/bin/bash

# cmdy smart installer/updater script
# Usage: 
#   curl -sSL https://raw.githubusercontent.com/jdpierce21/cmdy/master/install.sh | bash
#   ./install.sh [install|update] [git|download|auto]

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

# Check for force flag
FORCE_UPDATE=""
if [[ "$1" == "--force" ]]; then
    FORCE_UPDATE="--force"
fi

SOURCE_METHOD="auto"

echo -e "\n${BLUE}🔄 cmdy installer ... ${NC}\n"

# Function to detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "mac";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

# Function to find existing cmdy source
find_cmdy_source() {
    # Check current directory first
    if [[ -d ".git" && -f "main.go" && -f "config.yaml" ]]; then
        pwd
        return 0
    fi
    
    # Check common locations
    local locations=(
        "$HOME/cmdy"
        "$HOME/projects/cmdy"
        "$HOME/src/cmdy"
        "$HOME/dev/cmdy"
        "$HOME/code/cmdy"
        "$HOME/scripts/cmdy"
    )
    
    for location in "${locations[@]}"; do
        if [[ -d "$location/.git" && -f "$location/main.go" && -f "$location/config.yaml" ]]; then
            echo "$location"
            return 0
        fi
    done
    
    # Not found
    return 1
}

# Function to determine source method
determine_source_method() {
    case "$SOURCE_METHOD" in
        "git"|"download")
            echo "$SOURCE_METHOD"
            ;;
        "auto")
            if find_cmdy_source >/dev/null 2>&1; then
                echo "git"
            else
                echo "download"
            fi
            ;;
        *)
            echo "download"
            ;;
    esac
}

# Function to get latest remote version
get_latest_remote_version() {
    curl -s "https://api.github.com/repos/jdpierce21/cmdy/commits/master" | \
    grep '"sha"' | head -1 | cut -d'"' -f4
}

# Function to get installed version info
get_installed_version() {
    if [[ -f "$CONFIG_DIR/version.json" ]]; then
        grep '"build_hash"' "$CONFIG_DIR/version.json" | cut -d'"' -f4
    else
        echo ""
    fi
}

# Function to check if installation/update is needed
check_if_install_needed() {
    if [[ "$FORCE_UPDATE" == "--force" ]]; then
        echo -e "${YELLOW}🔄 Force install/update requested...${NC}"
        return 0  # Continue with install
    fi
    
    echo -e "${BLUE}🔍 Checking installation status...${NC}"
    
    # Check if cmdy is installed
    if [[ ! -f "$INSTALL_DIR/cmdy" && ! -f "$INSTALL_DIR/cmdy.bin" ]]; then
        echo -e "${BLUE}📦 cmdy not found, proceeding with installation...${NC}"
        return 0  # Continue with install
    fi
    
    # cmdy is installed, check versions
    local current_version
    current_version=$(get_installed_version)
    
    if [[ -z "$current_version" ]]; then
        echo -e "${YELLOW}ℹ️  No version info found, proceeding with update...${NC}"
        return 0
    fi
    
    # Get latest remote version
    local latest_version
    latest_version=$(get_latest_remote_version)
    
    if [[ -z "$latest_version" ]]; then
        echo -e "${YELLOW}⚠️  Could not check for updates, proceeding anyway...${NC}"
        return 0
    fi
    
    # Compare versions
    if [[ "$current_version" == "$latest_version" ]]; then
        echo -e "${GREEN}✓ Already up-to-date (build: ${current_version:0:7})${NC}"
        return 1  # Skip install
    else
        echo -e "${BLUE}🔄 New version available (${current_version:0:7} → ${latest_version:0:7})${NC}"
        return 0  # Continue with install
    fi
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

# Function to build and install cmdy from source
install_cmdy() {
    local source_method=$(determine_source_method)
    local status="🔨 Building cmdy from source..."
    local source_dir=""
    local cleanup_needed=false
    
    echo -e "${YELLOW}${status}${NC}"
    
    if [[ "$source_method" == "git" ]]; then
        # Use existing git repository
        source_dir=$(find_cmdy_source)
        if [[ -z "$source_dir" ]]; then
            echo -e "${RED}❌ Git source not found, falling back to download${NC}"
            source_method="download"
        else
            echo -e "${YELLOW}📁 Using existing source: $source_dir${NC}"
            cd "$source_dir"
            
            # Always pull latest changes when using git source
            echo -e "${YELLOW}🔄 Pulling latest changes...${NC}"
            git pull origin master > /dev/null 2>&1 || {
                echo -e "${RED}❌ Git pull failed${NC}"
                exit 1
            }
        fi
    fi
    
    if [[ "$source_method" == "download" ]]; then
        # Download fresh source
        TEMP_DIR=$(mktemp -d)
        source_dir="$TEMP_DIR"
        cleanup_needed=true
        cd "$TEMP_DIR"
        
        echo -e "${YELLOW}📥 Downloading source...${NC}"
        git clone "$REPO_URL.git" . > /dev/null 2>&1 || {
            echo -e "${RED}❌ Failed to download source${NC}"
            exit 1
        }
    fi
    
    # Build binary with consistent optimization and version embedding
    echo -e "${YELLOW}🔨 Building optimized binary...${NC}"
    local current_hash=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    local build_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    go build -ldflags="-s -w -X main.BuildVersion=$current_hash -X main.BuildDate=$build_date" -o cmdy > /dev/null 2>&1 || {
        echo -e "${RED}❌ Build failed${NC}"
        [[ "$cleanup_needed" == true ]] && rm -rf "$TEMP_DIR"
        exit 1
    }
    
    # Install binary (always use wrapper architecture)
    if [[ -f "cmdy" ]]; then
        mv cmdy "$INSTALL_DIR/cmdy.bin" > /dev/null 2>&1 || {
            echo -e "${RED}❌ Failed to install binary${NC}"
            [[ "$cleanup_needed" == true ]] && rm -rf "$TEMP_DIR"
            exit 1
        }
        chmod +x "$INSTALL_DIR/cmdy.bin"
        echo -e "${GREEN}✓ Binary installed${NC}"
        
        # Save version information
        echo -e "${YELLOW}📋 Saving version info...${NC}"
        mkdir -p "$CONFIG_DIR"
        cat > "$CONFIG_DIR/version.json" << EOF
{
  "build_hash": "$current_hash",
  "build_date": "$build_date",
  "install_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
        echo -e "${GREEN}✓ Version info saved${NC}"
    else
        echo -e "${RED}❌ Binary not found after build${NC}"
        [[ "$cleanup_needed" == true ]] && rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Handle config based on existing installation
    if [[ -f "$CONFIG_DIR/config.yaml" ]]; then
        # Existing config - preserve and backup new defaults
        echo -e "${YELLOW}📋 Preserving user configuration...${NC}"
        cp config.yaml "$CONFIG_DIR/config.yaml.new" > /dev/null 2>&1
        echo -e "${GREEN}✓ User config preserved, new defaults saved as config.yaml.new${NC}"
        
        # Update example scripts but preserve user scripts
        if [[ -d "$CONFIG_DIR/scripts" ]]; then
            cp -r scripts/examples "$CONFIG_DIR/scripts/" > /dev/null 2>&1
            chmod +x "$CONFIG_DIR/scripts/examples"/*.sh 2>/dev/null || true
            echo -e "${GREEN}✓ Example scripts updated${NC}"
        else
            cp -r scripts "$CONFIG_DIR/" > /dev/null 2>&1
            chmod +x "$CONFIG_DIR/scripts"/*.sh 2>/dev/null || true
            echo -e "${GREEN}✓ Scripts installed${NC}"
        fi
    else
        # Fresh install - copy everything
        echo -e "${YELLOW}📋 Installing configuration...${NC}"
        cp config.yaml "$CONFIG_DIR/" > /dev/null 2>&1
        cp -r scripts "$CONFIG_DIR/" > /dev/null 2>&1
        chmod +x "$CONFIG_DIR/scripts"/*.sh 2>/dev/null || true
        echo -e "${GREEN}✓ Configuration installed${NC}"
    fi
    
    # Cleanup if needed
    if [[ "$cleanup_needed" == true ]]; then
        cd "$HOME"
        rm -rf "$TEMP_DIR"
    fi
    
    echo -e "${GREEN}✅ Build and install completed${NC}"
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

# Main installation/update flow
main() {
    # Check if install/update is needed (may exit early if already up-to-date)
    if ! check_if_install_needed; then
        exit 0  # Already up-to-date, exit gracefully
    fi
    
    # Determine if this is fresh install or update for messaging
    local is_fresh_install=false
    if [[ ! -f "$INSTALL_DIR/cmdy" && ! -f "$INSTALL_DIR/cmdy.bin" ]]; then
        is_fresh_install=true
    fi
    
    # Install/update flow
    install_dependencies
    create_directories
    install_cmdy
    create_wrapper
    
    # Only setup PATH for fresh installs
    if [[ "$is_fresh_install" == true ]]; then
        setup_path
    fi
    
    verify_installation
    
    # Success messaging based on install type
    echo
    if [[ "$is_fresh_install" == true ]]; then
        echo -e "🎉🎉🎉 Installation completed successfully! 🎉🎉🎉"
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
    else
        echo -e "${GREEN}✓ Updated successfully!${NC}"
        echo
        echo -e "${BLUE}What was updated:${NC}"
        echo "  Binary: $INSTALL_DIR/cmdy.bin"
        echo "  Examples: $CONFIG_DIR/scripts/examples/"
        if [[ -f "$CONFIG_DIR/config.yaml.new" ]]; then
            echo "  New config reference: $CONFIG_DIR/config.yaml.new"
        fi
        echo
        echo -e "${BLUE}Your customizations preserved:${NC}"
        echo "  Config: $CONFIG_DIR/config.yaml"
        echo "  User scripts: $CONFIG_DIR/scripts/user/"
    fi
}

# Run main function
main "$@"