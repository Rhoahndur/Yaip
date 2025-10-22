#!/bin/bash

# iOS Simulator Network Control Script
# Easily toggle airplane mode / network connectivity

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Your simulators
SIMULATORS=(
    "Partner Device"
    "Main Simulator Device iPhone 17 Pro"
)

show_help() {
    echo -e "${BLUE}iOS Simulator Network Control${NC}"
    echo ""
    echo "Usage: $0 [off|on|status]"
    echo ""
    echo "Commands:"
    echo "  off     - Disable network (airplane mode)"
    echo "  on      - Enable network (restore connection)"
    echo "  status  - Show network status of running simulators"
    echo ""
    echo "Example:"
    echo "  $0 off    # Put all running simulators in airplane mode"
    echo "  $0 on     # Restore network to all running simulators"
    echo ""
}

get_booted_simulators() {
    for sim in "${SIMULATORS[@]}"; do
        UDID=$(xcrun simctl list devices | grep "$sim" | grep "Booted" | grep -E -o -i "([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})")
        if [ -n "$UDID" ]; then
            echo "$UDID:$sim"
        fi
    done
}

disable_network() {
    echo -e "${YELLOW}✈️  Enabling airplane mode...${NC}"
    echo ""
    
    while IFS=: read -r udid name; do
        if [ -n "$udid" ]; then
            echo -e "${BLUE}📱 $name${NC}"
            xcrun simctl status_bar "$udid" override --networkType disconnected
            echo -e "${GREEN}   ✅ Network disabled${NC}"
        fi
    done < <(get_booted_simulators)
    
    echo ""
    echo -e "${GREEN}✅ Airplane mode enabled on all running simulators${NC}"
    echo -e "${YELLOW}💡 Your app will now behave as if there's no network connection${NC}"
}

enable_network() {
    echo -e "${GREEN}📶 Restoring network connection...${NC}"
    echo ""
    
    while IFS=: read -r udid name; do
        if [ -n "$udid" ]; then
            echo -e "${BLUE}📱 $name${NC}"
            xcrun simctl status_bar "$udid" clear
            echo -e "${GREEN}   ✅ Network restored${NC}"
        fi
    done < <(get_booted_simulators)
    
    echo ""
    echo -e "${GREEN}✅ Network restored on all running simulators${NC}"
}

show_status() {
    echo -e "${BLUE}📊 Simulator Network Status${NC}"
    echo ""
    
    booted=$(get_booted_simulators)
    
    if [ -z "$booted" ]; then
        echo -e "${YELLOW}No simulators are currently running${NC}"
        exit 0
    fi
    
    while IFS=: read -r udid name; do
        if [ -n "$udid" ]; then
            echo -e "${BLUE}📱 $name${NC}"
            echo -e "   UDID: $udid"
            echo -e "${GREEN}   Status: Booted${NC}"
            echo ""
        fi
    done < <(echo "$booted")
}

# Main script
case "$1" in
    off|airplane)
        disable_network
        ;;
    on|restore)
        enable_network
        ;;
    status)
        show_status
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac

