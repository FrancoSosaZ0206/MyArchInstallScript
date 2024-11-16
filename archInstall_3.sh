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
# SECTION 15 - Special Packages Installation

# Turn Wi-Fi on (if not already)
sudo nmcli radio wifi on
# Connect to Wi-Fi or exit if failed to do so
sudo nmcli device wifi connect "${WIFI_SSID}" password "${WIFI_PASSWD}"
if [ $? -ne 0 ]; then
  echo "Error: Failed to connect to Wi-Fi."
  exit 1
fi


clear
# Add the AUR REPOSITORY (with yay)
# Install prerequisites for building AUR packages
sudo pacman -S git --needed --noconfirm

# Clone the yay repository
git clone https://aur.archlinux.org/yay.git /home/$USERNAME/yay

# Navigate to the yay directory and install yay
cd /home/$USERNAME/yay
makepkg -si --noconfirm

# Attempt to install visual studio code
# if it can't be installed with yay, attempt with flatpak
if ! yay -S visual-studio-code-bin --noconfirm; then
    sudo flatpak install flathub com.visualstudio.code -y
fi

# Go back to the root directory
cd /



# ############################################# #
# SECTION 16 - Install and Configure Hyprland
# and its Dependencies

# Install ML4W (setup for Hyprland)
# This also installs Hyprland, so no need to worry about that.

# Navigate to yay directory
cd /home/$USERNAME/yay
# Attempt to download and install required utilities and ML4W
if ! yay -S extra/hyprutils ml4w-hyprland --noconfirm; then
    clear
    read -p "WARNING: failed to download ML4W."
else
    read -p "ML4W downloaded successfully, proceeding with installation..."
    ml4w-hyprland-setup
fi



# ·············································· #
# ················· DEPRECATED ················· #
# ·············································· #

# # Define Hyprland and dependencies
# HYPRLAND_PACKAGES="hyprland \
# wayland wayland-protocols xorg-xwayland \
# wl-clipboard grim slurp wf-recorder \
# mako dunst \
# swaybg swaylock swayidle \
# waybar \
# xdg-desktop-portal xdg-desktop-portal-hyprland \
# kitty wofi"
# 
# # Install Hyprland and dependencies
# if ! sudo pacman -S ${HYPRLAND_PACKAGES} --noconfirm --needed; then
#   echo "WARNING: could not install Hyprland and its dependencies."
# fi
# 
# # Add nvidia to the MODULES array in /etc/mkinitcpio.conf
# sudo sed -i "s/^MODULES=(/&nvidia nvidia_modeset nvidia_uvm nvidia_drm/" /etc/mkinitcpio.conf
# 
# # Create and edit /etc/modprobe.d/nvidia.conf
# sudo touch /etc/modprobe.d/nvidia.conf
# echo 'options nvidia_drm modeset=1 fbdev=1' | sudo tee /etc/modprobe.d/nvidia.conf
# 
# # Rebuild initramfs
# sudo mkinitcpio -P
# 
# 
# # Create configuration directory for Hyprland
# sudo mkdir -p /home/$USERNAME/.config/hypr
# 
# # Basic Hyprland configuration file with Spanish (Latin America) layout
# sudo cat <<EOL > /home/$USERNAME/.config/hypr/hyprland.conf
# env = LIBVA_DRIVER_NAME,nvidia
# env = __GLX_VENDOR_LIBRARY_NAME,nvidia
# 
# cursor {
#     no_hardware_cursors = true
# }
# 
# monitor=,preferred,auto,1
# input {
#     kb_layout = "latam"
# }
# decoration {
#     rounding = 5
# }
# exec-once = swaybg -i /usr/share/backgrounds/gnome/adwaita-day.jpg
# bind = SUPER, RETURN, exec kitty
# bind = SUPER, D, exec wofi --show drun
# EOL
# 
# # Set up Wayland session entry for Hyprland (will show as an option on login screen)
# sudo cat <<EOL > /usr/share/wayland-sessions/hyprland.desktop
# [Desktop Entry]
# Name=Hyprland
# Comment=A dynamic tiling Wayland compositor
# Exec=Hyprland
# Type=Application
# DesktopNames=Hyprland
# EOL
# 
# # Set Wayland-related environment variables
# echo "XDG_SESSION_TYPE=wayland" | sudo tee -a /etc/environment
# echo "MOZ_ENABLE_WAYLAND=1" | sudo tee -a /etc/environment
# echo "QT_QPA_PLATFORM=wayland" | sudo tee -a /etc/environment

# ·············································· #
# ················· DEPRECATED ················· #
# ·············································· #



# ############################################# #
# SECTION 17 - Configuration and Tweaks

apply_setting() {
    "$@"
    if [ $? -ne 0 ]; then
        echo "WARNING: $1 failed to apply."
    fi
}

# Enable autologin for the user
sudo sed -i "/^\[daemon\]$/a AutomaticLoginEnable=True\nAutomaticLogin=${USERNAME}" /etc/gdm/custom.conf

# Set the GTK3 theme for legacy applications to Adwaita-dark
apply_setting gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'

# Add global aliases for yt-dlp commands
echo 'alias getMusic="yt-dlp -x --audio-format mp3 --audio-quality 0 --embed-metadata -P ~/Music -o \"%(artist)s - %(title)s.%(ext)s\""' | sudo tee -a /etc/bash.bashrc > /dev/null
echo 'alias getMusicWithMetadata="yt-dlp -x --audio-format mp3 --audio-quality 0 -P ~/Music"' | sudo tee -a /etc/bash.bashrc > /dev/null
echo 'alias getMusicList="yt-dlp -x --audio-format mp3 --audio-quality 0 --embed-metadata -P ~/Music -o \"%(artist)s - %(title)s.%(ext)s\" -a \"/run/media/fran/1TB/Franco/3. Música/2. Música Nueva/!yt-dlp/Batch_Downloads.txt\" --download-archive \"/run/media/fran/1TB/Franco/3. Música/2. Música Nueva/!yt-dlp/Downloaded_Files.txt\""' | sudo tee -a /etc/bash.bashrc > /dev/null

alias
read -p "yt-dlp aliases set..."

# ······································ #
# GNOME Settings configuration:
# ······································ #

# Set input language to Spanish and set as active:
apply_setting gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'latam')]"


# Night Light configuration:

# Enable from 18:00 to 10:00
apply_setting gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
apply_setting gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-from 18
apply_setting gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-to 10

# Set temperature to 3500 (1/4th of the bar in GNOME Settings > Display > Night Light)
apply_setting gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature 3500


# Set audacious as default music player
apply_setting xdg-mime default audacious.desktop audio/mpeg
# Set Image Viewer as default photos app
apply_setting xdg-mime default eog.desktop image/jpeg


# ······································ #
# GNOME Tweaks configuration:
# ······································ #

# Enable maximize and minimize titlebar buttons
apply_setting gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
# Set Appearance > Style > Legacy Applications to 'Adwaita-dark'
apply_setting gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"


# ······································ #
# GNOME Tweaks configuration:
# ······································ #

# Enable extensions
apply_setting gnome-extensions enable launch-new-instance@gnome-shell-extensions.gcampax.github.com
apply_setting gnome-extensions enable light-style@gnome-shell-extensions.gcampax.github.com
apply_setting gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com



# ############################################# #
# SECTION 18 - Cleanup and Debloat

# clear
# Remove unnecessary gnome apps (for me)
echo -e "\nAttempting to remove unnecessary gnome apps...\n"
PACKAGES="gnome-contacts gnome-maps gnome-music \
        gnome-weather gnome-tour gnome-system-monitor \
        totem malcontent epiphany snapshot"
pacman -R $PACKAGES --noconfirm
read -p "Press enter to continue..."

# clear
# Hide GNOME extensions
sudo sh -c "echo 'NoDisplay=true' >> /usr/share/applications/org.gnome.Extensions.desktop"

# Remove temporary file used for the scripts:
sudo rm /temp_vars.sh

if [ -f /temp_vars.sh ]; then
    # clear
    echo "Warning: temp_vars.sh could not be deleted."
fi

# Define the output file path
TODO_PATH="/home/$USERNAME/Documents/postInstall_todo.txt"

# Create the file
sudo touch "$TODO_PATH"
# Write the instructions to the file using a heredoc
sudo cat << EOF > "$TODO_PATH"
Post-installation process complete.
However, there are certain things that need
to be done manually.
Here's the list:

GNOME Settings:
- System >
    > Formats: set to 'Argentina'
    > Users: set user photo to one you like :) 
- Keyboard >
    > Input Sources: set input method language to 'Spanish (Latin American)'
    and put it to the top. Select it from the top bar, too.
    > Keyboard Shortcuts > View and Customize Shortcuts >
        > System:
            - Lock screen: rebind to 'Pause' ('Pausa' button on keyboard)
            - Log out: rebind to 'Super+L'
        > Custom Shortcuts - Add (name | command | shortcut):
            - Power Off | gnome-session-quit --power-off | Super+P
            - Reboot | gnome-session-quit --reboot | Super+R
            - Suspend | systemctl suspend | Super+S
            - Open Music Player | audacious | Super+M
- Displays > Night Light > 
    > Times: from 18:00 to 10:00 
    > Color Temperature: set the slider to 1/4 
- Apps > Default Apps: make sure
    - either Audacious or Rhythmbox are set for Music, and
    - set Photos to Image Viewer.
- Appearance: tune to your liking :) 

GNOME tweaks:
- Windows > Titlebar Buttons: toggle Maximize and Minimize on.
- Appearance > Styles: if not already, set 'Legacy Applications' to 'Adwaita-dark'

Extension Manager - toggle these on:
- Launch new instance
- Light Style
- Removable Drive Menu
- Status Icons
- User Themes

Audacious:
- Settings > Plugins: if not already, enable
    - General > Lyrics
    - General > Search Tool
    - Effect > Silence Removal

Rhythmbox:
- 'Three dots' >
    > View > Check 'Play Queue in Side Pane'
    > Preferences >
        > General > Visible Columns: check
            - Last played
            - Play count
        > Playback > Player Backend: enable Crossfade and set its duration to 1 second.
        > Music >
            > Library Location: check 'Watch my library for new files'
            > Library Structure > Preferred format: change it to 'MPEG Layer 3 Audio'.
        > Plugins: enable 'ReplayGain', and in Preferences, set 'Pre-amp' to '-8,0 dB'.

Others:
- Turn wi-fi on (and set password)
- Open Firefox and log into Mozilla, Google and GitHub (use phone and WhatsApp Web for this)
- Apps menu: group apps in folders
EOF

# Notify the user
# clear
head $TODO_PATH
echo '...'
echo "Post-installation to-do list has been saved to $TODO_PATH."

# Cleanup - Delete this script
sudo rm -- "$0"

exit 0


# ############################################# #
#               END OF THE SCRIPT
# ############################################# #
