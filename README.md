# Dotfiles

Personal configuration files for Hyprland and related tools.

## Setup Instructions

### Prerequisites

Install required packages:
```bash
sudo pacman -Syu hyprland kitty wofi vim waybar swaybg
```

### Symlinking Configuration Files

1. **Hyprland Configuration**
   ```bash
   # Create Hyprland config directory if it doesn't exist
   mkdir -p ~/.config/hypr
   
   # Symlink Hyprland config
   ln -sf ~/dotfiles/hyprland/hyprland.conf ~/.config/hypr/hyprland.conf
   ```

2. **Waybar Configuration**
   ```bash
   # Create Waybar config directory if it doesn't exist
   mkdir -p ~/.config/waybar
   
   # Symlink Waybar config files
   ln -sf ~/dotfiles/waybar/config.jsonc ~/.config/waybar/config.jsonc
   ln -sf ~/dotfiles/waybar/style.css ~/.config/waybar/style.css
   ```

3. **Wallpaper Setup**
   ```bash
   # Create Pictures directory and add your wallpaper
   mkdir -p ~/Pictures
   # Place your wallpaper at ~/Pictures/wallpaper.jpg
   ```

## Configuration Files

- `hyprland/hyprland.conf` - Hyprland window manager configuration
- `waybar/config.jsonc` - Waybar status bar configuration
- `waybar/style.css` - Waybar styling