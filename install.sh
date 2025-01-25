#!/usr/bin/env bash
set -o nounset -o pipefail -o errexit

# Color constants
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
elif [ -f /etc/debian_version ]; then
    OS="Debian"
elif [ -f /etc/redhat-release ]; then
    OS="RedHat"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
else
    OS="Unknown"
fi

# Check if we need sudo for a directory
need_sudo() {
    local dir="$1"
    # If directory doesn't exist, check parent directory
    if [ ! -e "$dir" ]; then
        dir=$(dirname "$dir")
    fi
    # Check if we can write to the directory
    [ ! -w "$dir" ]
}

# Check if we need sudo for any operations
check_sudo_requirement() {
    if need_sudo "/etc/haproxy" || need_sudo "/etc/haproxy/conf.d"; then
        echo -e "${YELLOW}Some operations require sudo access.${NC}"
        # Cache sudo credentials
        sudo -v
    fi
}

# Install HAProxy if not present
install_haproxy() {
    if ! command -v haproxy &> /dev/null; then
        echo -e "${YELLOW}Installing HAProxy...${NC}"
        case $OS in
            "Ubuntu"|"Debian")
                sudo apt-get update
                sudo apt-get install -y haproxy
                ;;
            "Fedora"|"RedHat")
                sudo dnf install -y haproxy
                ;;
            "macOS")
                brew install haproxy
                ;;
            *)
                echo -e "${RED}Unsupported operating system: $OS${NC}"
                echo "Please install HAProxy manually and run this script again."
                exit 1
                ;;
        esac
    else
        echo -e "${GREEN}HAProxy is already installed${NC}"
    fi
}

# Create required directories
create_directories() {
    echo -e "${YELLOW}Creating required directories...${NC}"
    if need_sudo "/etc/haproxy"; then
        sudo mkdir -p /etc/haproxy/conf.d
    else
        mkdir -p /etc/haproxy/conf.d
    fi
}

# Copy configuration files
copy_files() {
    echo -e "${YELLOW}Copying configuration files...${NC}"
    if need_sudo "/etc/haproxy/conf.d"; then
        sudo cp config/haproxy/conf.d/openai-proxy.cfg /etc/haproxy/conf.d/
    else
        cp config/haproxy/conf.d/openai-proxy.cfg /etc/haproxy/conf.d/
    fi
}

# Verify configuration
verify_config() {
    echo -e "${YELLOW}Verifying HAProxy configuration...${NC}"
    if need_sudo "/etc/haproxy"; then
        sudo haproxy -c -f /etc/haproxy/haproxy.cfg
    else
        haproxy -c -f /etc/haproxy/haproxy.cfg
    fi && echo -e "${GREEN}Configuration is valid${NC}" || {
        echo -e "${RED}Configuration check failed${NC}"
        exit 1
    }
}

# Restart HAProxy
restart_haproxy() {
    echo -e "${YELLOW}Restarting HAProxy...${NC}"
    case $OS in
        "Ubuntu"|"Debian"|"Fedora"|"RedHat")
            if need_sudo "/etc/haproxy"; then
                sudo systemctl restart haproxy
            else
                systemctl restart haproxy
            fi
            ;;
        "macOS")
            brew services restart haproxy
            ;;
        *)
            echo -e "${RED}Please restart HAProxy manually${NC}"
            ;;
    esac
}

# Main installation process
main() {
    echo -e "${GREEN}Installing OpenAI Proxy...${NC}"
    
    install_haproxy
    create_directories
    copy_files
    verify_config
    restart_haproxy
    
    echo -e "${GREEN}Installation complete!${NC}"
    echo -e "OpenAI Proxy is now available at ${YELLOW}http://localhost:2020${NC}"
    echo -e "To use with OpenAI tools, set: ${YELLOW}export OPENAI_BASE_URL=http://localhost:2020/v1${NC}"
}

# Run main installation
check_sudo_requirement
main
