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

clear
# Add the AUR REPOSITORY (with yay)
# Install prerequisites for building AUR packages
sudo pacman -S git --needed --noconfirm

# Clone the yay repository
git clone https://aur.archlinux.org/yay.git ~/yay

# Navigate to the yay directory and install yay
cd ~/yay
makepkg -si --noconfirm

# Attempt to install visual studio code
# if it can't be installed with yay, attempt with flatpak
if ! yay -S visual-studio-code-bin --noconfirm; then
    flatpak install flathub com.visualstudio.code -y
fi



# ############################################# #
# SECTION 17 - Configuration and Tweaks

# Enable autologin for the user
sudo sed -i "/^\[daemon\]$/a AutomaticLoginEnable=True\nAutomaticLogin=${USERNAME}" /etc/gdm/custom.conf

# Add global aliases for yt-dlp commands
echo 'alias getMusic="yt-dlp -x --audio-format mp3 --audio-quality 0 --embed-metadata -P ~/Music -o \"%(artist)s - %(title)s.%(ext)s\""' >> /etc/bash.bashrc
echo 'alias getMusicWithMetadata="yt-dlp -x --audio-format mp3 --audio-quality 0 -P ~/Music"' >> /etc/bash.bashrc
echo 'alias getMusicList="yt-dlp -x --audio-format mp3 --audio-quality 0 --embed-metadata -P ~/Music -o \"%(artist)s - %(title)s.%(ext)s\" -a \"/run/media/fran/1TB/Franco/3. Música/2. Música Nueva/!yt-dlp/Batch_Downloads.txt\" --download-archive \"/run/media/fran/1TB/Franco/3. Música/2. Música Nueva/!yt-dlp/Downloaded_Files.txt\""' >> /etc/bash.bashrc



# ############################################# #
# SECTION 18 - Cleanup and Debloat

clear
# Remove unnecessary gnome apps (for me)
echo -e "\nAttempting to remove unnecessary gnome apps...\n"
PACKAGES="gnome-contacts gnome-maps gnome-music \
        gnome-weather gnome-tour gnome-system-monitor \
        totem malcontent epiphany snapshot"
pacman -R $PACKAGES --noconfirm
read -p "Press enter to continue..."

# Remove temporary file used for the scripts:
rm /temp_vars.sh

if [ -f /temp_vars.sh ]; then
    echo "Warning: temp_vars.sh could not be deleted."
fi

# Print list of things that need to be done manually:
clear
echo -e "Post-installation process complete.\n \
However, there are certain things that need\n \
to be done manaully.\n \
Here's the list:\n\n \

GNOME Settings:\n \
- System > \n \
\t > Language: if set to 'unspecified', set to 'English (US)'\n \
\t > Formats: set to 'Argentina'\n \
\t > Users: set user photo to one you like :) \n \
- Keyboard: set input method language to 'Spanish (Latin American)'\n \
\t and put it to the top. Select it from the top bar, too.\n \
- Displays > Night Light > \n
\t > Times: from 18:00 to 10:00 \n \
\t > Color Temperature: set the slider to 1/4 \n \
- Apps > Default Apps: make sure Rhythmbox is set for Music,\n \
\t and set Photos to Image Viewer.\n \
- Appearance: tune to your liking :) \n\n \

GNOME tweaks:\n \
- Windows > Titlebar Buttons: toggle Maximize and Minimize on.\n \
- Appearance > Styles: if not already, \
set 'Legacy Applications' to 'Adwaita-dark'\n\n \

Others:\n \
- Turn wi-fi on (and set password)\n \
- Test bluetooth\n \
- Open Firefox and log into all necessary accounts \
(use phone and WhatsApp for this)\n \
- Apps menu: group apps in folders\n"

# Cleanup - Delete this script
rm -- "$0"

exit 0


# ############################################# #
#               END OF THE SCRIPT
# ############################################# #
