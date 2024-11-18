#!/usr/bin/bash
# Fran's Arch Linux Automated Installation Script (part 3)

# ############################################# #
# FIRST STEPS

# Import variables from part 1
echo -e "\nImporting data...\n"
if [ ! -f "$HOME/temp_vars.sh" ]; then
    echo "Error: Data file $HOME/temp_vars.sh not found. Could not import data."
    exit 1
fi

source "$HOME/temp_vars.sh"


# GRUB MULTI-OS BOOT CONFIGURATION

# Enabling os-prober to detect other systems in GRUB:
sudo sed -i "s/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/" /etc/default/grub

# Run os-prober to detect other OSs
if ! sudo os-prober; then
  read -p "WARNING: os-prober did not detect any other operating systems."
fi

# Make grub config
if ! sudo grub-mkconfig -o /boot/grub/grub.cfg; then
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

# ······································ #
# Add the AUR repository (with yay):
# ······································ #

clear
# Install prerequisites for building AUR packages
sudo pacman -S git --needed --noconfirm

# Temporarily allow the current user to run sudo without a password for pacman commands (makepkg)
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/pacman" | sudo tee -a /etc/sudoers.d/makepkg

# Clone the yay repository
git clone https://aur.archlinux.org/yay.git $HOME/yay

# Navigate to the yay directory and install yay
cd $HOME/yay
makepkg -si --noconfirm


# ······································ #
# Install VS Code:
# ······································ #

# if it can't be installed with yay, attempt with flatpak
if ! yay -S visual-studio-code-bin --noconfirm; then
    sudo flatpak install flathub com.visualstudio.code -y
fi

# Go back to the home directory
cd


# ······································ #
# Install Webcord (better Discord client):
# ······································ #

# Clone the webcord repository
git clone https://aur.archlinux.org/webcord-git.git $HOME/webcord-git

# Navigate to the webcord directory and install it
cd $HOME/webcord-git
makepkg -si --noconfirm


# ······································ #
# Install DroidCam (use your phone as webcam):
# ······································ #

# Navigate to /tmp/
cd /tmp/
# Fetch the program compressed file
curl -o droidcam_latest.zip https://files.dev47apps.net/linux/droidcam_2.1.3.zip
# If it passes the integrity check (check this sha1sum key from website)
if sha1sum droidcam_latest.zip | grep 2646edd5ad2cfb046c9c695fa6d564d33be0f38b; then
    # then unzip the file
    unzip droidcam_latest.zip -d droidcam
    # navigate to the resulting folder
    cd droidcam
    # Install the program
    sudo ./install-client
    # Enable video by running this install script
    sudo ./install-video

else # if it didn't pass the integrity check,
    # then remove the file
    rm -f droidcam_latest.zip
    # print a warning and move on
    echo "WARNING: DroidCam didn't pass integrity check. Could not install it." &
    sleep 2
fi

cd


# ······································ #
# Install Bibata cursor themes:
# ······································ #

echo "Downloading Bibata cursor theme..."

cd $HOME/yay

if ! yay -S bibata-cursor-theme-bin --noconfirm; then    
    echo "Failed downlading from yay. Attempting with tar version..."

    # Define variables
    BIBATA_URL="https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata.tar.xz"
    TARGET_DIR="/usr/share/icons"
    TEMP_DIR="/tmp/bibata_install"

    # Create a temporary installation directory and navigate to it
    if ! mkdir -p "$TEMP_DIR"; then
        echo "ERROR: Failed to create temporary directory."
    elif ! cd "$TEMP_DIR"; then
        echo "ERROR: Failed to access temporary directory."
    elif ! curl -LO "$BIBATA_URL"; then
        echo "ERROR: Failed to download Bibata tar file from GitHub."
    elif ! tar -xf Bibata.tar.xz; then
        echo "ERROR: Failed to extract Bibata cursor theme."
    elif ! sudo mv Bibata-* "$TARGET_DIR"; then
        echo "ERROR: Failed to move Bibata cursor theme to $TARGET_DIR."
    else
        # Cleanup
        rm -rf "$TEMP_DIR"

        echo "Bibata cursor theme installed successfully to $TARGET_DIR." &
    fi
fi

cd


# ······································ #
# Install Papirus icon themes:
# ······································ #

# Install for the root directory (recommended)
if ! wget -qO- https://git.io/papirus-icon-theme-install | sh; then
    echo "ERROR: Failed to install Papirus icon themes."
elif [ ! -d "/usr/share/icons/Papirus" ]; then
    echo "ERROR: Papirus installation completed, but they weren't found in /usr/share/icons."
else
    echo "Papirus icon themes installed successfully!"
fi



# ############################################# #
# SECTION 16 - Configuration and Tweaks

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
echo 'alias getMusicList="yt-dlp -x --audio-format mp3 --audio-quality 0 --embed-metadata -P ~/Music -o \"%(artist)s - %(title)s.%(ext)s\" -a \"/mnt/1TB/Franco/3. Música/2. Música Nueva/!yt-dlp/Batch_Downloads.txt\" --download-archive \"/mnt/1TB/Franco/3. Música/2. Música Nueva/!yt-dlp/Downloaded_Files.txt\""' | sudo tee -a /etc/bash.bashrc > /dev/null

tail /etc/bash.bashrc
echo "yt-dlp aliases set..." &
sleep 3


# ······································ #
# GNOME Settings configuration:
# ······································ #

# Set input language to Spanish and set as active:
apply_setting gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'latam')]"

# Set formats region to Argentina
apply_setting gsettings set org.gnome.system.locale region 'es_AR.UTF-8'


# Enable automatic Date & Time
sudo timedatectl set-ntp true  # Enable Network Time Protocol (NTP)

# Show Weekdays
apply_setting gsettings set org.gnome.desktop.interface clock-show-weekday true

# Set timezone to GMT-03 (Buenos Aires)
apply_setting timedatectl set-timezone America/Argentina/Buenos_Aires



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

# Set cursor to Bibata-Modern-Ice
apply_setting gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'

# Set icons to Papirus
apply_setting gsettings set org.gnome.desktop.interface icon-theme 'Papirus'


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
            audacious & sleep 3 # Allow time for initialization
        fi
        echo "Closing Audacious..."
        kill $(pgrep audacious) & sleep 2 # Ensure proper shutdown
    }

    MUSIC_LIB="${TB_MOUNTPOINT}/Franco/3. Música/1. Biblioteca de Música"

    # Open and close Audacious to initialize files
    echo "Letting Audacious to initialize its files..."
    open_close_audacious

    # Update configuration
    echo "Configuring Audacious settings..."
    cat << EOF > "$HOME/.config/audacious/config"
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
# SECTION 17 - Cleanup and Debloat

# clear
# Remove unnecessary gnome apps (for me)
echo -e "\nAttempting to remove unnecessary gnome apps...\n"
PACKAGES="gnome-contacts gnome-maps gnome-music \
        gnome-weather gnome-tour gnome-system-monitor \
        totem malcontent epiphany snapshot"
sudo pacman -R $PACKAGES --noconfirm

# clear
# Hide GNOME extensions
sudo sh -c "echo 'NoDisplay=true' >> /usr/share/applications/org.gnome.Extensions.desktop"

# Define the output file path
TODO_PATH="$HOME/Documents/postInstall_todo.txt"
TEMP_PATH="$TODO_PATH.tmp"

# Ensure the directory exists
if ! mkdir -p "$(dirname "$TODO_PATH")"; then
    echo "ERROR: Could not create directory for TODO_PATH: $(dirname "$TODO_PATH")"
# Create the file
elif ! touch "$TEMP_PATH"; then
    echo "ERROR: Could not create file at $TEMP_PATH."
else # Write the instructions to the file using a heredoc
    cat << EOF > "$TEMP_PATH"
Post-installation process complete.
However, there are certain things that need
to be done manually.
Here's the list:

GNOME Settings:
- System > Users: set user photo to one you like :) 
- Keyboard > Keyboard Shortcuts > View and Customize Shortcuts >
    > System:
        - Lock screen: rebind to 'Super+Pause' ('Pausa' button on spanish keyboard)
    > Custom Shortcuts - Add:
        NAME                      | COMMAND                           | SHORTCUT
        Power Off                 | gnome-session-quit --power-off    | Super+P
        Reboot                    | gnome-session-quit --reboot       | Super+R
        Log Out                   | gnome-session-quit --logout       | Super+L
        Suspend                   | systemctl suspend                 | Super+S
        Open Music Player         | audacious                         | Super+M
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
- Settings > Plugins: enable
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
            - Year
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
    if mv "$TEMP_PATH" "$TODO_PATH"; then
        head -n 30 "$TODO_PATH"
        echo '...'
        echo "Post-installation to-do list has been saved to $TODO_PATH."
    else
        echo "ERROR: failed to save the to-do list."
    fi
fi


# Remove temporary file used for the scripts
sudo rm -f "$HOME/temp_vars.sh" || echo "Warning: temp_vars.sh could not be deleted."

# Delete this script
sudo rm -f -- "$0" || echo "Warning: $0 couldn't be deleted."

# Remove the passwordless sudo rule from sudoers
echo "Restoring sudoers configuration..."
sudo EDITOR='sed -i "/^${USERNAME} ALL=(ALL) NOPASSWD: ALL$/d"' visudo

# Remove .bashrc modifications for script execution
sed -i '/archInstall_3.sh/,/fi/d' "$HOME/.bashrc"
cat "$HOME/.bashrc" & sleep 3

# Exit the script
exit 0


# ############################################# #
#               END OF THE SCRIPT
# ############################################# #
