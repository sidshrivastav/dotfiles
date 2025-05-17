#!/bin/bash

# Update system and install Hyprland
echo "Updating system and installing Hyprland Kitty..."
sudo pacman -Syu --noconfirm hyprland kitty wofi vim waybar

# Check if dotfiles directory exists
DOTFILES_DIR=~/dotfiles
if [ -d "$DOTFILES_DIR" ]; then
    # Symlink dotfiles
    echo "Symlinking dotfiles..."

    # Ensure the config directory for Hyprland exists
    CONFIG_DIR=~/.config/hypr
    if [ ! -d "$CONFIG_DIR" ]; then
        echo "Creating the Hyprland config directory..."
        mkdir -p "$CONFIG_DIR"
    fi

    # Check if the Hyprland config exists
    if [ -f "$CONFIG_DIR/hyprland.conf" ]; then
        # Copy hyprland.conf to dotfiles directory
        HYPRLAND_CONFIG_DIR="$DOTFILES_DIR/hyprland"
        mkdir -p "$HYPRLAND_CONFIG_DIR"

        echo "Copying hyprland.conf to dotfiles..."
        cp "$CONFIG_DIR/hyprland.conf" "$HYPRLAND_CONFIG_DIR/"

        # Symlink Hyprland config
        echo "Symlinking Hyprland config..."
        ln -sf "$HYPRLAND_CONFIG_DIR/hyprland.conf" "$CONFIG_DIR/hyprland.conf"
    else
        echo "Hyprland config file not found at $CONFIG_DIR/hyprland.conf"
    fi
    
else
    echo "Dotfiles directory not found: $DOTFILES_DIR"
    exit 1
fi

echo "Setup complete!"
