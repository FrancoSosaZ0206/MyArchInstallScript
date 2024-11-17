#!/usr/bin/bash
# Fran's Arch Linux Automated Installation Script (part 3)

# ############################################# #
# FIRST STEPS

# Import variables from part 1
echo -e "\nImporting data...\n"
if [ ! -f /temp_vars.sh ]; then
    echo "Error: Data file /temp_vars.sh not found. Could not import data."
    exit 1
fi

source /temp_vars.sh


# GRUB MULTI-OS BOOT CONFIGURATION

# Enabling os-prober to detect other systems in GRUB:
sed -i "s/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/" /etc/default/grub

# Run os-prober to detect other OSs
clear
if ! os-prober; then
  read -p "WARNING: os-prober did not detect any other operating systems."
fi

# Make grub config
clear
if ! grub-mkconfig -o /boot/grub/grub.cfg; then
  echo "ERROR: Failed to generate GRUB configuration!"
  exit 1
fi

echo "GRUB configuration updated with detected OSs."


# Turn Wi-Fi on (if not already)
sudo nmcli radio wifi on

# Connect to Wi-Fi or exit if failed to do so
sudo nmcli device wifi connect "${WIFI_SSID}" password "${WIFI_PASSWD}"
if [ $? -ne 0 ]; then
  echo "Error: Failed to connect to Wi-Fi."
  exit 1
fi

# Mount 1TB disk (used for Audacious config later on)
TB_MOUNTPOINT="/mnt/1TB"
sudo mount --mkdir /dev/sda2 "${TB_MOUNTPOINT}"



# ############################################# #
# SECTION 15 - Special Packages Installation


clear
# Add the AUR REPOSITORY (with yay)
# Install prerequisites for building AUR packages
sudo pacman -S git --needed --noconfirm

# Clone the yay repository
git clone https://aur.archlinux.org/yay.git $HOME/yay

# Navigate to the yay directory and install yay
cd $HOME/yay
makepkg -si --noconfirm

# Attempt to install visual studio code
# if it can't be installed with yay, attempt with flatpak
if ! yay -S visual-studio-code-bin --noconfirm; then
    sudo flatpak install flathub com.visualstudio.code -y
fi

# Go back to the home directory
cd



# ############################################# #
# SECTION 16 - Install and Configure Hyprland
# and its Dependencies

# Install ML4W (setup for Hyprland)
# This also installs Hyprland, so no need to worry about that.

# Navigate to yay directory
cd $HOME/yay
# Attempt to download and install required utilities and ML4W
if ! yay -S extra/hyprutils ml4w-hyprland --noconfirm; then
    clear
    read -p "WARNING: failed to download ML4W."
else
    read -p "ML4W downloaded successfully, proceeding with installation..."
    ml4w-hyprland-setup
fi

# Go back to the home directory
cd



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
echo 'alias getMusicList="yt-dlp -x --audio-format mp3 --audio-quality 0 --embed-metadata -P ~/Music -o \"%(artist)s - %(title)s.%(ext)s\" -a \"/mnt/1TB/Franco/3. Música/2. Música Nueva/!yt-dlp/Batch_Downloads.txt\" --download-archive \"$/mnt/1TB/Franco/3. Música/2. Música Nueva/!yt-dlp/Downloaded_Files.txt\""' | sudo tee -a /etc/bash.bashrc > /dev/null

alias
read -p "yt-dlp aliases set..."

# ······································ #
# GNOME Settings configuration:
# ······································ #

# Set input language to Spanish and set as active:
apply_setting gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'latam')]"
# Set formats region to Argentina
gsettings set org.gnome.system.locale region 'es_AR.UTF-8'


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
apply_setting xdg-mime default org.gnome.Loupe.desktop image/jpeg



# ······································ #
# GNOME Tweaks configuration:
# ······································ #

# Enable maximize and minimize titlebar buttons
apply_setting gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
# Set Appearance > Style > Legacy Applications to 'Adwaita-dark'
apply_setting gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"


# ······································ #
# GNOME Extensions configuration:
# ······································ #

# Check if tweaks exist first before enabling
apply_gnome_extension() {
    if gnome-extensions list | grep -q "$1"; then
        apply_setting gnome-extensions enable "$1"
    else
        echo "Extension $1 not found. Skipping."
    fi
}

# Enable extensions
apply_gnome_extension "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
apply_gnome_extension "light-style@gnome-shell-extensions.gcampax.github.com"
apply_gnome_extension "user-theme@gnome-shell-extensions.gcampax.github.com"


# ······································ #
# Audacious configuration:
# ······································ #

# If audacious is installed, proceed
if ! command -v audacious &>/dev/null; then
    echo "Audacious is not installed. Skipping configuration."
else
    open_close_audacious() {
        # open Audacious, if not already
        if ! pgrep -x "audacious" > /dev/null; then
            echo "Starting Audacious..."
            audacious &
            sleep 3 # Allow time for initialization
        fi
        echo "Closing Audacious..."
        audacious -q
        sleep 2 # Ensure proper shutdown
    }

    MUSIC_LIB="${TB_MOUNTPOINT}/Franco/3. Música/1. Biblioteca de Música"

    # Open and close Audacious to initialize files
    echo "Letting Audacious to initialize its files..."
    open_close_audacious

    # Update configuration
    echo "Configuring Audacious settings..."
    cat << EOF > "/home/${USERNAME}/.config/audacious/config"
[audacious]
replay_gain_mode=2
replay_gain_preamp=-8
show_numbers_in_pl=TRUE
shuffle=TRUE

[audgui]
filesel_path=${MUSIC_LIB}

[audqt]
theme=dark

[compressor]
center=0.6
range=0.7

[crossfade]
length=1
manual_length=1.5
no_fade_in=TRUE

[qtui]
player_height=1011
player_width=960

[search-tool]
monitor=TRUE
rescan_on_startup=TRUE
EOF
    echo "Configuration file updated."

    # Update playlist directory
    if [ -d "$MUSIC_LIB" ]; then
        audtool playlist-clear
        audtool playlist-addurl "$MUSIC_LIB"
        echo "Playlist updated with music from $MUSIC_LIB"
    else
        echo "Playlist directory does not exist: $MUSIC_LIB"
    fi

    # Restart Audacious to finalize configuration
    echo "Restarting Audacious..."
    open_close_audacious


    echo "Configuration completed!"
fi





# ############################################# #
# SECTION 18 - Cleanup and Debloat

# clear
# Remove unnecessary gnome apps (for me)
echo -e "\nAttempting to remove unnecessary gnome apps...\n"
PACKAGES="gnome-contacts gnome-maps gnome-music \
        gnome-weather gnome-tour gnome-system-monitor \
        totem malcontent epiphany snapshot"
sudo pacman -R $PACKAGES --noconfirm
read -p "Press enter to continue..."

# clear
# Hide GNOME extensions
sudo sh -c "echo 'NoDisplay=true' >> /usr/share/applications/org.gnome.Extensions.desktop"

# Define the output file path
TODO_PATH="$HOME/Documents/postInstall_todo.txt"

# Create the file
sudo touch "$TODO_PATH"
# Write the instructions to the file using a heredoc
sudo cat << EOF > "$TODO_PATH"
Post-installation process complete.
However, there are certain things that need
to be done manually.
Here's the list:

GNOME Settings:
- System > Users: set user photo to one you like :) 
- Keyboard > Keyboard Shortcuts > View and Customize Shortcuts >
        > System:
            - Lock screen: rebind to 'Pause' ('Pausa' button on keyboard)
        > Custom Shortcuts - Add (name | command | shortcut):
            - Power Off | gnome-session-quit --power-off | Super+P
            - Reboot | gnome-session-quit --reboot | Super+R
            - Log Out | gnome-session-quit --logout | Super+L
            - Suspend | systemctl suspend | Super+S
            - Open Music Player | audacious | Super+M
- Apps > Default Apps: make sure
    - either Audacious or Rhythmbox are set for Music, and
    - Image Viewer is set for Photos.
- Appearance: tune to your liking :) 

Disks:
    - Select 1,0 TB Hard Disk (partition 2 out of 3)
    - Go to 'Gears button' > 'Edit Mount Options...'
    - Make sure:
        - 'User Session Defaults' is toggled off
        - If not already,
            - Toggle on 'Mount at system startup'
            - Toggle on 'Show in user interface'
    - Set 'Identify As' to 'LABEL=1TB'
    - Set 'Filesystem Type' to 'ntfs'
    - Click Ok, set your user password and exit.

Audacious:
- Settings > Plugins: if not already, enable
    - General > Album Art
    - General > Lyrics
    - General > Search Tool
    - Effect > Crossfade
    - Effect > Dynamic Range Compressor
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
- Open Firefox and log into Mozilla, Google and GitHub (use phone and WhatsApp Web for this)
- Apps menu: organize - group apps in folders.
EOF

# Notify the user
# clear
head $TODO_PATH
echo '...'
echo "Post-installation to-do list has been saved to $TODO_PATH."


# Remove temporary file used for the scripts
if [ ! sudo rm -f /temp_vars.sh ]; then
    # clear
    echo "Warning: temp_vars.sh could not be deleted."
fi

# Delete this script
sudo rm -- "$0"

exit 0


# ############################################# #
#               END OF THE SCRIPT
# ############################################# #
