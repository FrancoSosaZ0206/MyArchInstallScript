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

# Set the GTK3 theme for legacy applications to Adwaita-dark
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'

# Add global aliases for yt-dlp commands
sudo echo 'alias getMusic="yt-dlp -x --audio-format mp3 --audio-quality 0 --embed-metadata -P ~/Music -o \"%(artist)s - %(title)s.%(ext)s\""' >> /etc/bash.bashrc
sudo echo 'alias getMusicWithMetadata="yt-dlp -x --audio-format mp3 --audio-quality 0 -P ~/Music"' >> /etc/bash.bashrc
sudo echo 'alias getMusicList="yt-dlp -x --audio-format mp3 --audio-quality 0 --embed-metadata -P ~/Music -o \"%(artist)s - %(title)s.%(ext)s\" -a \"/run/media/fran/1TB/Franco/3. Música/2. Música Nueva/!yt-dlp/Batch_Downloads.txt\" --download-archive \"/run/media/fran/1TB/Franco/3. Música/2. Música Nueva/!yt-dlp/Downloaded_Files.txt\""' >> /etc/bash.bashrc

alias
read -p "yt-dlp aliases set..."

# Perform automounting if the user chose to do so
if [ -n "$AUTOMOUNT_DISK" ]; then
    read -p "Automounting $AUTOMOUNT_DISK..."

    MOUNT_POINT="/run/media/$USERNAME/"
    # Set the mount point based on the disk label
    if [ -n "$AUTOMOUNT_LABEL" ]; then
        MOUNT_POINT+="$(echo $AUTOMOUNT_LABEL | tr ' ' '_')"
    else # fallback to default
        MOUNT_POINT+="$AUTOMOUNT_DISK"
    fi
    read -p "Setting mount point to '$MOUNT_POINT'"

    # Get the user's UID and GID
    USER_UID=$(id -u "$USERNAME")
    USER_GID=$(id -g "$USERNAME")

    # Construct fstab entry
    AUTOMOUNT_FSTAB_ENTRY="UUID=$AUTOMOUNT_UUID  $MOUNT_POINT  $AUTOMOUNT_FSTYPE  defaults,noatime,uid=$USER_UID,gid=$USER_GID  0  2"

    # Add the fstab entry
    if ! sudo echo "$AUTOMOUNT_FSTAB_ENTRY" | sudo tee -a /etc/fstab; then
      echo "Error: Failed to add FSTAB entry." >&2
      exit 1
    else
        # Create the mount point directory
        sudo mkdir -p "$MOUNT_POINT"
        read -p "FSTAB entry added successfully."
    fi
fi



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

clear
sudo sh -c "echo 'NoDisplay=true' >> /usr/share/applications/org.gnome.Extensions.desktop"
tail /usr/share/applications/org.gnome.Extensions.desktop
read -p "GNOME Extensions hidden..."

# Remove temporary file used for the scripts:
rm /temp_vars.sh

if [ -f /temp_vars.sh ]; then
    clear
    read -p "Warning: temp_vars.sh could not be deleted."
fi

# Define the output file path
TODO_PATH="/home/$USER/Documents/postInstall_todo.txt"

# Write the instructions to the file using a heredoc
cat << EOF > "$TODO_PATH"
Post-installation process complete.
However, there are certain things that need
to be done manually.
Here's the list:

GNOME Settings:
- System >
    > Language: if set to 'unspecified', set to 'English (US)'
    > Formats: set to 'Argentina'
    > Users: set user photo to one you like :) 
- Keyboard: set input method language to 'Spanish (Latin American)'
    and put it to the top. Select it from the top bar, too.
- Displays > Night Light > 
    > Times: from 18:00 to 10:00 
    > Color Temperature: set the slider to 1/4 
- Apps > Default Apps: make sure Rhythmbox is set for Music,
    and set Photos to Image Viewer.
- Appearance: tune to your liking :) 

GNOME tweaks:
- Windows > Titlebar Buttons: toggle Maximize and Minimize on.
- Appearance > Styles: if not already, set 'Legacy Applications' to 'Adwaita-dark'

Audacious:
- Settings > 
    > Appearance > 
        > Theme: set to 'Dark'
        > Icon theme: set to 'Flat (Dark)'
    > Audio > ReplayGain: check 'Enable', set mode to 'Based on shuffle'
      and set 'Amplify all files' to '-8.0' dB.
    > Plugins: if not already, enable
        - General > Lyrics
        - General > Search Tool
        - Effect > Crossfade (set 'On automatic song change > Overlap' to 1 second)
        - Effect > Dynamic Range Compressor (set 'Center volume' to '0.6' and 'Dynamic Range' to '0.7')
        - Effect > Silence Removal

Others:
- Turn wi-fi on (and set password)
- Test bluetooth
- Open Firefox and log into all necessary accounts (use phone and WhatsApp for this)
- Apps menu: group apps in folders
EOF

# Notify the user
clear
head $TODO_PATH
echo "Post-installation to-do list has been saved to $TODO_PATH."

# Cleanup - Delete this script
rm -- "$0"

exit 0


# ############################################# #
#               END OF THE SCRIPT
# ############################################# #
