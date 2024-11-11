#!/usr/bin/bash
# Fran's Arch Linux Automated Installation Script (part 3)


# ############################################# #
# SECTION 15 - Cleanup and Debloat

# Remove the previous script:
rm /archInstall_2.sh

if [ -f /archInstall_2.sh ]; then
    clear
    echo "Warning: archInstall_2.sh could not be deleted."
    read -p "Press enter to continue..."
fi

# Remove unnecessary gnome apps (for me)
# PACKAGES="gnome-contacts gnome-maps gnome-music \
#         gnome-weather gnome-tour gnome-system-monitor \
#         yelp totem malcontent"
# pacman -Rns $PACKAGES --noconfirm



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
sudo sed -i "/^\[daemon\]$/a AutomaticLoginEnable=True\nAutomaticLogin=yourusername" /etc/gdm/custom.conf
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
#               END OF THE SCRIPT
# ############################################# #
