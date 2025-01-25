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
    sudo mkdir -p /etc/haproxy/conf.d
    sudo mkdir -p /etc/haproxy/pages
}

# Copy configuration files
copy_files() {
    echo -e "${YELLOW}Copying configuration files...${NC}"
    sudo cp config/haproxy/conf.d/openai-proxy.cfg /etc/haproxy/conf.d/
    sudo cp config/haproxy/pages/welcome.http /etc/haproxy/pages/
}

# Verify configuration
verify_config() {
    echo -e "${YELLOW}Verifying HAProxy configuration...${NC}"
    if sudo haproxy -c -f /etc/haproxy/haproxy.cfg; then
        echo -e "${GREEN}Configuration is valid${NC}"
    else
        echo -e "${RED}Configuration check failed${NC}"
        exit 1
    fi
}

# Restart HAProxy
restart_haproxy() {
    echo -e "${YELLOW}Restarting HAProxy...${NC}"
    case $OS in
        "Ubuntu"|"Debian"|"Fedora"|"RedHat")
            sudo systemctl restart haproxy
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
main
