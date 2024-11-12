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

# Attempt to install davinci resolve
if ! yay -S davinci-resolve --noconfirm; then
    clear
    echo "WARNING: could not install DaVinci Resolve."
    read -p "Press enter to continue..."
fi

clear
# Install Wine
echo "Installing Wine..."
sudo pacman -S wine winetricks --needed --noconfirm

clear
# Download AIMP installer
echo "Downloading and installing AIMP..."
AIMP_INSTALLER_URL="https://download.aimp.ru/AIMP/aimp_5.11.2427.exe"
curl -L -o ~/Downloads/aimp_installer.exe "$AIMP_INSTALLER_URL"

# Run AIMP installer with Wine
wine ~/Downloads/aimp_installer.exe

# Create a .desktop file for AIMP (this will add it to your application menu)
echo "[Desktop Entry]
Name=AIMP
Exec=wine ~/.wine/drive_c/Program\\ Files/AIMP/AIMP.exe
Type=Application
Icon=~/.wine/drive_c/Program\\ Files/AIMP/aimp_icon.png
Categories=Audio;Player;" > ~/.local/share/applications/aimp.desktop

# Update permissions for the .desktop file to make it executable
chmod +x ~/.local/share/applications/aimp.desktop

clear
echo "AIMP installation complete! You can find it in your applications menu."



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

exit 0


# ############################################# #
#               END OF THE SCRIPT
# ############################################# #
