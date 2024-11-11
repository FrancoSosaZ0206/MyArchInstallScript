#!/usr/bin/bash
# Fran's Arch Linux Automated Installation Script (part 3)

# ############################################# #
# Import variables from part 1

echo -e "\nImporting data...\n"
if [ ! -f /temp_vars.sh ]; then
    echo "Error: Data file /temp_vars.sh not found. Could not import data."
    exit 1
fi

source /temp_vars.sh



# ############################################# #
# SECTION 15 - Install and Configure Hyprland
# and its Dependencies

# Define Hyprland and dependencies
HYPRLAND_PACKAGES="hyprland \
wayland wayland-protocols xorg-xwayland \
wl-clipboard grim slurp wf-recorder \
mako dunst \
swaybg swaylock swayidle \
waybar \
xdg-desktop-portal xdg-desktop-portal-hyprland \
kitty wofi"

# Install Hyprland and dependencies
if ! pacman -S ${HYPRLAND_PACKAGES} --noconfirm --needed; then
  echo "WARNING: could not install Hyprland and its dependencies."
fi

# Create configuration directory for Hyprland
mkdir -p ~/.config/hypr

# Basic Hyprland configuration file with Spanish (Latin America) layout
cat <<EOL > ~/.config/hypr/hyprland.conf
monitor=,preferred,auto,1
input {
    kb_layout = "latam"
}
decoration {
    rounding = 5
}
exec-once = swaybg -i /usr/share/backgrounds/gnome/adwaita-day.jpg
bind = SUPER, RETURN, exec kitty
bind = SUPER, D, exec wofi --show drun
EOL

# Set up Wayland session entry for Hyprland (will show as an option on login screen)
cat <<EOL > /usr/share/wayland-sessions/hyprland.desktop
[Desktop Entry]
Name=Hyprland
Comment=A dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
DesktopNames=Hyprland
EOL

# Set Wayland-related environment variables
echo "XDG_SESSION_TYPE=wayland" | tee -a /etc/environment
echo "MOZ_ENABLE_WAYLAND=1" | tee -a /etc/environment
echo "QT_QPA_PLATFORM=wayland" | tee -a /etc/environment



# ############################################# #
# SECTION 16 - Special Packages Installation

# Attempt to install visual studio code
# if it can't be installed with yay, attempt with flatpak
if ! yay -S visual-studio-code-bin --noconfirm; then
    flatpak install flathub com.visualstudio.code -y
fi

# Attempt to install davinci resolve

if ! yay -S davinci-resolve --noconfirm; then
    clear
    echo "WARNING: could not install DaVinci Resolve."
    read -p "Press enter to continue..."
fi



# ############################################# #
# SECTION 17 - Configuration and Tweaks

# Set Spanish (Latin American) as the keyboard layout
clear
localectl set-x11-keymap latam
read -p "Press enter to continue..."

# Enable autologin for the user
clear
sudo sed -i "/^\[daemon\]$/a AutomaticLoginEnable=True\nAutomaticLogin=${USERNAME}" /etc/gdm/custom.conf
read -p "Press enter to continue..."

# Set custom keyboard shortcuts
clear
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/']"
read -p "Press enter to continue..."

# Shortcut for Power Off
clear
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name "Power Off"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command "gnome-session-quit --power-off"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding "<Alt>F4"
read -p "Press enter to continue..."

# Shortcut for Reboot
clear
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name "Reboot"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command "gnome-session-quit --reboot"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding "<Alt>R"
read -p "Press enter to continue..."

# Shortcut for Suspend
clear
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ name "Suspend"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ command "systemctl suspend"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ binding "<Alt>S"
read -p "Press enter to continue..."

# Shortcut for Opening Music Player (Rhythmbox)
clear
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ name "Open Music Player"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ command "rhythmbox"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ binding "<Super>M"
read -p "Press enter to continue..."

# Set Adwaita-dark as the GTK theme
clear
gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
read -p "Press enter to continue..."



# ############################################# #
# SECTION 17 - Cleanup and Debloat

# Remove unnecessary gnome apps (for me)
PACKAGES="gnome-contacts gnome-maps gnome-music \
        gnome-weather gnome-tour gnome-system-monitor \
        totem malcontent epiphany"
pacman -R $PACKAGES --noconfirm

# Remove temporary file used for the scripts:
rm /temp_vars.sh

if [ -f /temp_vars.sh ]; then
    echo "Warning: temp_vars.sh could not be deleted."
fi

# Cleanup - Delete this script
rm -- "$0"



# ############################################# #
#               END OF THE SCRIPT
# ############################################# #
