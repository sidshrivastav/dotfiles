#!/bin/bash

# WiFi Auto-Connect Script for Hyprland/EndeavourOS
# Automatically connects to WiFi using NetworkManager

# Configuration
LOG_FILE="$HOME/.wifi-autoconnect.log"
CONFIG_FILE="$HOME/.wifi-autoconnect.conf"
MAX_RETRIES=3
RETRY_DELAY=5

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    if [[ "$2" != "silent" ]]; then
        echo -e "$1"
    fi
}

# Error handling
error_exit() {
    log "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# Success message
success() {
    log "${GREEN}SUCCESS: $1${NC}"
}

# Warning message
warning() {
    log "${YELLOW}WARNING: $1${NC}"
}

# Info message
info() {
    log "${BLUE}INFO: $1${NC}"
}

# Check if NetworkManager is running
check_networkmanager() {
    if ! systemctl is-active --quiet NetworkManager; then
        error_exit "NetworkManager is not running. Please start it with: sudo systemctl start NetworkManager"
    fi
}

# Get WiFi interface automatically
get_wifi_interface() {
    local interface=$(nmcli device status | awk '/wifi/ && /connected|disconnected/ {print $1; exit}')
    if [[ -z "$interface" ]]; then
        interface=$(ip link show | grep -oE 'wl[a-z0-9]+' | head -1)
    fi
    if [[ -z "$interface" ]]; then
        error_exit "No WiFi interface found"
    fi
    echo "$interface"
}

# Disable WiFi power management
disable_wifi_power_management() {
    local interface="$1"
    if command -v iwconfig &> /dev/null; then
        sudo iwconfig "$interface" power off 2>/dev/null || true
        info "Disabled power management for $interface"
    fi
}

# Check if connected to WiFi
is_connected() {
    local interface="$1"
    nmcli device status | grep -q "$interface.*connected"
}

# Get current connection name
get_current_connection() {
    nmcli device status | awk '/wifi.*connected/ {for(i=4;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/[[:space:]]*$//'
}

# Connect to WiFi
connect_wifi() {
    local retries=0
    local interface=$(get_wifi_interface)
    
    info "WiFi interface detected: $interface"
    disable_wifi_power_management "$interface"
    
    # Check if already connected
    if is_connected "$interface"; then
        local current_conn=$(get_current_connection)
        success "Already connected to: $current_conn"
        return 0
    fi
    
    info "Attempting to connect to WiFi..."
    
    # Try to connect to saved connections with auto-connect enabled
    while [[ $retries -lt $MAX_RETRIES ]]; do
        # Get connections with autoconnect enabled
        local connections=$(nmcli connection show | awk '/wifi/ {print $1}' | head -5)
        
        for conn in $connections; do
            info "Trying connection: $conn"
            if nmcli connection up "$conn" 2>/dev/null; then
                success "Connected to: $conn"
                # Ensure autoconnect is enabled
                nmcli connection modify "$conn" connection.autoconnect yes 2>/dev/null
                return 0
            fi
        done
        
        ((retries++))
        if [[ $retries -lt $MAX_RETRIES ]]; then
            warning "Connection attempt $retries failed. Retrying in $RETRY_DELAY seconds..."
            sleep $RETRY_DELAY
        fi
    done
    
    error_exit "Failed to connect after $MAX_RETRIES attempts"
}

# Scan for networks
scan_networks() {
    info "Scanning for available networks..."
    nmcli device wifi rescan 2>/dev/null || true
    sleep 2
    nmcli device wifi list
}

# Show connection status
show_status() {
    local interface=$(get_wifi_interface)
    
    echo -e "${BLUE}=== WiFi Connection Status ===${NC}"
    echo "Interface: $interface"
    
    if is_connected "$interface"; then
        local current_conn=$(get_current_connection)
        echo -e "Status: ${GREEN}Connected${NC}"
        echo "Network: $current_conn"
        
        # Show IP and signal strength
        local ip=$(ip addr show "$interface" | grep -oE 'inet [0-9.]+' | cut -d' ' -f2)
        echo "IP Address: ${ip:-N/A}"
        
        local signal=$(nmcli device wifi | grep "^\*" | awk '{print $(NF-1)}')
        echo "Signal Strength: ${signal:-N/A}"
    else
        echo -e "Status: ${RED}Disconnected${NC}"
    fi
    
    echo -e "${BLUE}=== Available Networks ===${NC}"
    nmcli device wifi list | head -10
}

# Force reconnection
reconnect_wifi() {
    local interface=$(get_wifi_interface)
    info "Forcing WiFi reconnection..."
    
    # Disconnect current connection
    if is_connected "$interface"; then
        local current_conn=$(get_current_connection)
        info "Disconnecting from: $current_conn"
        nmcli device disconnect "$interface" 2>/dev/null || true
        sleep 2
    fi
    
    # Reconnect
    connect_wifi
}

# Disconnect WiFi
disconnect_wifi() {
    local interface=$(get_wifi_interface)
    info "Disconnecting WiFi..."
    
    if is_connected "$interface"; then
        nmcli device disconnect "$interface"
        success "WiFi disconnected"
    else
        warning "WiFi already disconnected"
    fi
}

# Show usage
usage() {
    echo "Usage: $0 [command]"
    echo "Commands:"
    echo "  (no args)   - Connect to WiFi automatically"
    echo "  status      - Show connection status"
    echo "  reconnect   - Force reconnection"
    echo "  disconnect  - Disconnect WiFi"
    echo "  scan        - Scan for available networks"
    echo "  help        - Show this help message"
}

# Main function
main() {
    # Create log file if it doesn't exist
    touch "$LOG_FILE"
    
    # Check NetworkManager
    check_networkmanager
    
    case "${1:-connect}" in
        "connect"|"")
            connect_wifi
            ;;
        "status")
            show_status
            ;;
        "reconnect")
            reconnect_wifi
            ;;
        "disconnect")
            disconnect_wifi
            ;;
        "scan")
            scan_networks
            ;;
        "help"|"-h"|"--help")
            usage
            ;;
        *)
            echo "Unknown command: $1"
            usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"