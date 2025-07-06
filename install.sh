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


echo -e "\n${BLUE}cmdy - powerful CLI, modern UX${NC}\n"

# Function to print standardized status messages
print_status() {
    local status="$1"
    local message="$2"
    
    case "$status" in
        "pass"|"success"|"ok")
            echo -e "${GREEN}✅ ${message}${NC}"
            ;;
        "fail"|"error"|"err")
            echo -e "${RED}❌ ${message}${NC}"
            ;;
        "warn"|"warning")
            echo -e "${YELLOW}⚠️  ${message}${NC}"
            ;;
        "info"|"note")
            echo -e "${BLUE}ℹ️  ${message}${NC}"
            ;;
        "progress"|"working")
            echo -e "${message}"
            ;;
        *)
            echo -e "${message}"
            ;;
    esac
}

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
        echo -e "⚠️ Force install/update requested... "
        return 0  # Continue with install
    fi
    
    echo -e "🔍 Checking installation status..."
    
    # Check if cmdy is installed
    if [[ ! -f "$INSTALL_DIR/cmdy" && ! -f "$INSTALL_DIR/cmdy.bin" ]]; then
        echo -e "📦 cmdy not found, proceeding with installation..."
        return 0  # Continue with install
    fi
    
    # cmdy is installed, check versions
    local current_version
    current_version=$(get_installed_version)
    
    if [[ -z "$current_version" ]]; then
        echo -e "⚠️ No version info found, proceeding with update..."
        return 0
    fi
    
    # Get latest remote version
    local latest_version
    latest_version=$(get_latest_remote_version)
    
    if [[ -z "$latest_version" ]]; then
        echo -e "⚠️ Could not check for updates, proceeding anyway..."
        return 0
    fi
    
    # Compare versions
    if [[ "$current_version" == "$latest_version" ]]; then
        echo -e "👍 Already up-to-date (build: ${current_version:0:7})${NC}"
        return 1  # Skip install
    else
        echo -e "$🎂 New version available (${current_version:0:7} → ${latest_version:0:7})${NC}"
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
    print_status "success" "📦 Checking dependencies"
}

# Function to create directories
create_directories() {
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR"
    print_status "success" "📁 Creating directories"
}

# Function to build and install cmdy from source
install_cmdy() {
    local status="🔨 Building cmdy from source... ✅"
    local source_dir=""
    local cleanup_needed=false
    
    echo -e "${status}"
    
    # Try to use existing git source first, fallback to download
    source_dir=$(find_cmdy_source)
    if [[ -n "$source_dir" ]]; then
        # Use existing git repository
        echo -e "📁 Using existing source: $source_dir"
        cd "$source_dir"
        
        # Always pull latest changes when using git source
        echo -e "🔄 Pulling latest changes..."
        git pull origin master > /dev/null 2>&1 || {
            echo -e "${RED}❌ Git pull failed${NC}"
            exit 1
        }
    else
        # Download fresh source
        TEMP_DIR=$(mktemp -d)
        source_dir="$TEMP_DIR"
        cleanup_needed=true
        cd "$TEMP_DIR"
        
        echo -e "📥 Downloading source..."
        git clone "$REPO_URL.git" . > /dev/null 2>&1 || {
            echo -e "${RED}❌ Failed to download source${NC}"
            exit 1
        }
    fi
    
    # Build binary with consistent optimization and version embedding
    echo -e "🔨 Building optimized binary..."
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

        # Save version information
        echo -e "📋 Saving version info..."
        mkdir -p "$CONFIG_DIR"
        cat > "$CONFIG_DIR/version.json" << EOF
{
  "build_hash": "$current_hash",
  "build_date": "$build_date",
  "install_date": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
    else
        echo -e "${RED}❌ Binary not found after build${NC}"
        [[ "$cleanup_needed" == true ]] && rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Handle config based on existing installation
    if [[ -f "$CONFIG_DIR/config.yaml" ]]; then
        # Existing config - preserve and backup new defaults
        echo -e "📋 Preserving user configuration..."
        cp config.yaml "$CONFIG_DIR/config.yaml.new" > /dev/null 2>&1
        
        # Update example scripts but preserve user scripts
        if [[ -d "$CONFIG_DIR/scripts" ]]; then
            cp -r scripts/examples "$CONFIG_DIR/scripts/" > /dev/null 2>&1
            chmod +x "$CONFIG_DIR/scripts/examples"/*.sh 2>/dev/null || true
        else
            cp -r scripts "$CONFIG_DIR/" > /dev/null 2>&1
            chmod +x "$CONFIG_DIR/scripts"/*.sh 2>/dev/null || true
            print_status "success" "Scripts installed"
        fi
    else
        # Fresh install - copy everything
        echo -e "📋 Installing configuration..."
        cp config.yaml "$CONFIG_DIR/" > /dev/null 2>&1
        cp -r scripts "$CONFIG_DIR/" > /dev/null 2>&1
        chmod +x "$CONFIG_DIR/scripts"/*.sh 2>/dev/null || true
        print_status "success" "Configuration installed"
    fi
    
    # Cleanup if needed
    if [[ "$cleanup_needed" == true ]]; then
        cd "$HOME"
        rm -rf "$TEMP_DIR"
    fi
    
    print_status "success" "Build and install completed"
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
        print_status "success" "🔧 Setting up PATH"
    elif [[ -n "$SHELL_RC" ]]; then
        print_status "warn" "🔧 Setting up PATH - PATH may not be updated for new shells"
    else
        print_status "fail" "🔧 Setting up PATH - Could not determine or modify shell rc file"
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
        print_status "success" "📝 Creating wrapper script"
    else
        print_status "fail" "📝 Creating wrapper script - Failed to create wrapper"
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
        print_status "success" "🔍 Verifying installation"
    else
        print_status "fail" "🔍 Verifying installation - One or more checks failed"
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
    echo -e "🎉🎉🎉 Install/update completed successfully! 🎉🎉🎉"
    if [[ "$is_fresh_install" == true ]]; then
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
        echo ""
    fi
}

# Run main function
main "$@"