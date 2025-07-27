#!/bin/bash

# WiFi Setup Script for Hyprland/EndeavourOS
# Interactive configuration for WiFi auto-connect

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration files
CONFIG_FILE="$HOME/.wifi-autoconnect.conf"
DOTFILES_CONFIG="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/config.conf"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/wifi-autoconnect.sh"

# Load configuration from dotfiles
load_dotfiles_config() {
    if [[ -f "$DOTFILES_CONFIG" ]]; then
        source "$DOTFILES_CONFIG"
        HYPRLAND_CONFIG="$HYPRLAND_CONFIG_PATH"
        success "Loaded configuration from: $DOTFILES_CONFIG"
    else
        # Fallback to default paths
        HYPRLAND_CONFIG="$HOME/.config/hypr/hyprland.conf"
        warning "Configuration file not found, using defaults"
    fi
}

# Helper functions
print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}   WiFi Auto-Connect Setup${NC}"
    echo -e "${CYAN}================================${NC}"
    echo
}

print_step() {
    echo -e "${BLUE}[STEP $1]${NC} $2"
    echo
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

info() {
    echo -e "${CYAN}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_step "1" "Checking system prerequisites..."
    
    # Check if NetworkManager is installed
    if ! command -v nmcli &> /dev/null; then
        error "NetworkManager (nmcli) is not installed"
        echo "Install it with: sudo pacman -S networkmanager"
        exit 1
    fi
    success "NetworkManager is installed"
    
    # Check if NetworkManager is running
    if ! systemctl is-active --quiet NetworkManager; then
        warning "NetworkManager is not running"
        echo "Starting NetworkManager..."
        if sudo systemctl start NetworkManager; then
            success "NetworkManager started"
        else
            error "Failed to start NetworkManager"
            exit 1
        fi
    else
        success "NetworkManager is running"
    fi
    
    # Check WiFi interface
    local interface=$(nmcli device status | awk '/wifi/ {print $1; exit}')
    if [[ -z "$interface" ]]; then
        error "No WiFi interface found"
        exit 1
    fi
    success "WiFi interface found: $interface"
    
    echo
}

# Scan and display available networks
scan_networks() {
    print_step "2" "Scanning for available WiFi networks..."
    
    info "Refreshing network list..."
    nmcli device wifi rescan 2>/dev/null || true
    sleep 3
    
    echo -e "${CYAN}Available networks:${NC}"
    echo "----------------------------------------"
    nmcli device wifi list --rescan no | head -15
    echo
}

# Interactive network selection and configuration
configure_network() {
    print_step "3" "Network configuration..."
    
    while true; do
        echo -e "${CYAN}Choose an option:${NC}"
        echo "1) Connect to a visible network"
        echo "2) Add a hidden network"
        echo "3) Use existing saved connection"
        echo "4) Skip network configuration"
        echo
        read -p "Enter choice (1-4): " choice
        
        case $choice in
            1)
                configure_visible_network
                break
                ;;
            2)
                configure_hidden_network
                break
                ;;
            3)
                use_existing_connection
                break
                ;;
            4)
                info "Skipping network configuration"
                break
                ;;
            *)
                error "Invalid choice. Please enter 1-4."
                ;;
        esac
    done
    echo
}

# Configure visible network
configure_visible_network() {
    echo
    nmcli device wifi list --rescan no | head -10
    echo
    read -p "Enter the SSID (network name): " ssid
    
    if [[ -z "$ssid" ]]; then
        error "SSID cannot be empty"
        return 1
    fi
    
    # Check if network is open or secured
    local security=$(nmcli device wifi list | grep "^$ssid" | awk '{print $(NF-2)}')
    
    if [[ "$security" == "--" ]]; then
        info "Network appears to be open (no password required)"
        connect_to_network "$ssid" ""
    else
        echo -n "Enter password: "
        read -s password
        echo
        connect_to_network "$ssid" "$password"
    fi
}

# Configure hidden network
configure_hidden_network() {
    echo
    read -p "Enter the hidden network SSID: " ssid
    echo -n "Enter password: "
    read -s password
    echo
    
    if [[ -z "$ssid" ]]; then
        error "SSID cannot be empty"
        return 1
    fi
    
    info "Adding hidden network: $ssid"
    if nmcli connection add type wifi con-name "$ssid" ssid "$ssid" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$password" connection.autoconnect yes; then
        success "Hidden network added successfully"
        if nmcli connection up "$ssid"; then
            success "Connected to hidden network: $ssid"
        else
            warning "Network added but connection failed. Check credentials."
        fi
    else
        error "Failed to add hidden network"
    fi
}

# Use existing connection
use_existing_connection() {
    echo
    echo -e "${CYAN}Saved WiFi connections:${NC}"
    nmcli connection show | grep wifi
    echo
    
    read -p "Enter connection name to use (or press Enter to skip): " conn_name
    
    if [[ -n "$conn_name" ]]; then
        # Enable autoconnect for this connection
        if nmcli connection modify "$conn_name" connection.autoconnect yes; then
            success "Enabled autoconnect for: $conn_name"
            if nmcli connection up "$conn_name"; then
                success "Connected to: $conn_name"
            else
                warning "Failed to connect. Connection may be out of range."
            fi
        else
            error "Failed to modify connection: $conn_name"
        fi
    fi
}

# Connect to network
connect_to_network() {
    local ssid="$1"
    local password="$2"
    
    info "Connecting to: $ssid"
    
    if [[ -n "$password" ]]; then
        if nmcli device wifi connect "$ssid" password "$password"; then
            success "Connected to: $ssid"
            # Ensure autoconnect is enabled
            nmcli connection modify "$ssid" connection.autoconnect yes 2>/dev/null
            success "Enabled autoconnect for: $ssid"
        else
            error "Failed to connect to: $ssid"
            return 1
        fi
    else
        if nmcli device wifi connect "$ssid"; then
            success "Connected to open network: $ssid"
            nmcli connection modify "$ssid" connection.autoconnect yes 2>/dev/null
        else
            error "Failed to connect to: $ssid"
            return 1
        fi
    fi
}

# Setup script permissions
setup_script_permissions() {
    print_step "4" "Setting up script permissions..."
    
    if [[ -f "$SCRIPT_PATH" ]]; then
        chmod +x "$SCRIPT_PATH"
        success "Made wifi-autoconnect.sh executable"
    else
        error "wifi-autoconnect.sh not found at: $SCRIPT_PATH"
        return 1
    fi
    echo
}

# Integrate with Hyprland
integrate_hyprland() {
    print_step "5" "Hyprland integration..."
    
    # Load configuration first
    load_dotfiles_config
    
    if [[ ! -f "$HYPRLAND_CONFIG" ]]; then
        error "Hyprland config not found at: $HYPRLAND_CONFIG"
        echo "Please update the HYPRLAND_CONFIG_PATH in wifi-config.conf"
        return 1
    fi
    
    # Check if already integrated
    if grep -q "wifi-autoconnect.sh" "$HYPRLAND_CONFIG"; then
        warning "WiFi auto-connect already integrated in Hyprland config"
    else
        echo
        echo -e "${CYAN}Add WiFi auto-connect to Hyprland startup?${NC}"
        echo "Script path: $WIFI_SCRIPT_PATH"
        echo "Hyprland config: $HYPRLAND_CONFIG"
        read -p "This will modify your hyprland.conf file (y/N): " add_to_hypr
        
        if [[ "$add_to_hypr" =~ ^[Yy]$ ]]; then
            echo "" >> "$HYPRLAND_CONFIG"
            echo "# WiFi auto-connect" >> "$HYPRLAND_CONFIG"
            echo "exec-once = $WIFI_SCRIPT_PATH" >> "$HYPRLAND_CONFIG"
            success "Added WiFi auto-connect to Hyprland startup"
        else
            info "Skipped Hyprland integration"
            echo "To manually add, append this line to your hyprland.conf:"
            echo "exec-once = $WIFI_SCRIPT_PATH"
        fi
    fi
    echo
}

# Test the setup
test_setup() {
    print_step "6" "Testing the setup..."
    
    info "Testing script execution..."
    if "$SCRIPT_PATH" status; then
        success "Script executed successfully"
    else
        error "Script execution failed"
        return 1
    fi
    echo
}

# Show final instructions
show_instructions() {
    print_step "7" "Setup complete! Usage instructions:"
    
    # Load config for final display
    load_dotfiles_config
    
    echo -e "${GREEN}Available commands:${NC}"
    echo "• $WIFI_SCRIPT_PATH              - Auto-connect to WiFi"
    echo "• $WIFI_SCRIPT_PATH status       - Show connection status"
    echo "• $WIFI_SCRIPT_PATH reconnect    - Force reconnection"
    echo "• $WIFI_SCRIPT_PATH disconnect   - Disconnect WiFi"
    echo "• $WIFI_SCRIPT_PATH scan         - Scan for networks"
    echo
    
    echo -e "${GREEN}Configuration:${NC}"
    echo "• Main config: $DOTFILES_CONFIG"
    echo "• Update paths in config.conf for different users/setups"
    echo "• Example config: config.conf.example"
    echo "• Hyprland config: $HYPRLAND_CONFIG"
    echo
    
    echo -e "${GREEN}Startup behavior:${NC}"
    echo "• Script will run automatically when Hyprland starts"
    echo "• It will attempt to connect to saved networks with autoconnect enabled"
    echo "• Logs are saved to: ~/.wifi-autoconnect.log"
    echo
    
    echo -e "${GREEN}For other users:${NC}"
    echo "• Copy config.conf.example to config.conf"
    echo "• Update paths in config.conf to match your setup"
    echo "• Copy wifi-autoconnect.sh and wifi-setup.sh"
    echo "• Run ./wifi-setup.sh to configure"
    echo
    
    echo -e "${GREEN}Troubleshooting:${NC}"
    echo "• Check logs: tail -f ~/.wifi-autoconnect.log"
    echo "• Manual connect: $WIFI_SCRIPT_PATH"
    echo "• Restart NetworkManager: sudo systemctl restart NetworkManager"
    echo
    
    echo -e "${CYAN}Setup completed successfully!${NC}"
    echo -e "${CYAN}Reboot to test automatic WiFi connection.${NC}"
}

# Main function
main() {
    clear
    print_header
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        error "Do not run this script as root"
        exit 1
    fi
    
    # Run setup steps
    check_prerequisites
    scan_networks
    configure_network
    setup_script_permissions
    integrate_hyprland
    test_setup
    show_instructions
}

# Run main function
main "$@"