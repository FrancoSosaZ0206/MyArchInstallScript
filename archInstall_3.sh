#!/usr/bin/bash
# Fran's Arch Linux Automated Installation Script (part 3)

# ############################################# #
#               GLOBAL VARIABLES
# ############################################# #

TB_MOUNTPOINT=""



# ############################################# #
# FIRST STEPS

# ······································ #
# Import variables from part 1
# ······································ #

import_variables() {
    echo -e "\nImporting data...\n"
    if [ ! -f "$HOME/temp_vars.sh" ]; then
        echo "Error: Data file $HOME/temp_vars.sh not found. Could not import data."
        exit 1
    fi

    source "$HOME/temp_vars.sh"
}


# ······································ #
# GRUB multi-os boot configuration:
# ······································ #

grub_update() {
    echo -e "\nConfiguring GRUB...\n"
    
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
}


# ······································ #
# Wi-Fi setup:
# ······································ #

wifi_setup() {
    echo -e "\nSetting up Wi-Fi...\n"
    
    # Turn Wi-Fi on (if not already)
    sudo nmcli radio wifi on

    # Connect to Wi-Fi or exit if failed to do so
    sudo nmcli device wifi connect "${WIFI_SSID}" password "${WIFI_PASSWD}"
    if [ $? -ne 0 ]; then
    echo "Error: Failed to connect to Wi-Fi."
    exit 1
    fi
}


# ······································ #
# Disks Mounting:
# ······································ #

mount_disk() {
    echo -e "\nMounting 1TB disk...\n"

    # Mount 1TB disk (used for Audacious config later on)
    TB_MOUNTPOINT="/mnt/1TB"
    sudo mount --mkdir /dev/sda2 "${TB_MOUNTPOINT}"
}



# ############################################# #
# SECTION 15 - Special Packages Installation

# ······································ #
# Add the AUR repository (with yay):
# ······································ #

aur_setup() {
    clear
    echo -e "\nAdding the AUR repository...\n"

    # Install prerequisites for building AUR packages
    sudo pacman -S git --needed --noconfirm

    # Clone the yay repository
    git clone https://aur.archlinux.org/yay.git $HOME/yay

    # Navigate to the yay directory and install yay
    cd $HOME/yay && makepkg -si --noconfirm

    cd
}


# ······································ #
# Install VS Code:
# ······································ #

vscode() {
    echo -e "\nInstalling Visual Studio Code...\n"

    # if it can't be installed with yay, attempt with flatpak
    if ! yay -S visual-studio-code-bin --noconfirm; then
        sudo flatpak install flathub com.visualstudio.code -y
    fi

    cd
}


# ······································ #
# Install Webcord (better Discord client):
# ······································ #

webcord() {
    echo -e "\nInstalling WebCord...\n"

    # Clone the webcord repository
    git clone https://aur.archlinux.org/webcord-git.git $HOME/webcord-git

    # Navigate to the webcord directory and install it
    cd $HOME/webcord-git && makepkg -si --noconfirm

    cd
}


# ······································ #
# Install DroidCam (use your phone as webcam):
# ······································ #

droidcam() {
    echo -e "\nInstalling DroidCam...\n"

    cd ~/yay/
    if ! yay -S droidcam v4l2loopback-dc-dkms --noconfirm; then
        echo -e "\nWARNING: could not install droidcam.\n"
    else
        echo -e "\nDroidCam installed successfully!\n"
    fi

    sleep 2
    cd
}


# ······································ #
# Install Bibata cursor themes:
# ······································ #

bibata() {
    echo -e "\nInstalling Bibata cursor themes...\n"

    cd $HOME/yay

    if ! yay -S bibata-cursor-theme-bin --noconfirm; then    
        echo "Failed downlading from yay. Attempting with tar version..."

        # Define variables
        local BIBATA_URL="https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/Bibata.tar.xz"
        local TARGET_DIR="/usr/share/icons"
        local TEMP_DIR="/tmp/bibata_install"

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
}


# ······································ #
# Install Papirus icon themes:
# ······································ #

papirus() {
    echo -e "\nInstalling Papirus icon themes...\n"

    # Install for the root directory (recommended)
    if ! wget -qO- https://git.io/papirus-icon-theme-install | sh; then
        echo "ERROR: Failed to install Papirus icon themes."
    elif [ ! -d "/usr/share/icons/Papirus" ]; then
        echo "ERROR: Papirus installation completed, but they weren't found in /usr/share/icons."
    else
        echo "Papirus icon themes installed successfully!"
    fi
}


# ······································ #
# Install Cascadia Code custom font:
# ······································ #

cascadia_font() {
    echo -e "\nInstalling Cascadia Code custom font...\n"

    # Set variables
    local FONT_NAME="CascadiaCode"
    local FONT_VERSION="latest"
    local DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/${FONT_VERSION}/download/${FONT_NAME}.zip"
    local FONT_DIR="$HOME/.local/share/fonts/NerdFonts"

    # Create font directory if it doesn't exist
    mkdir -p "$FONT_DIR"

    # Download the font file
    echo "Downloading $FONT_NAME Nerd font..."
    curl -L "$DOWNLOAD_URL" -o "/tmp/${FONT_NAME}.zip"

    # Install the font
    if [[ $? -ne 0 ]]; then
        echo "WARNING: Failed to donwload $FONT_NAME."
    else
        # Extract the font files
        echo "Extracting fonts..."
        unzip -q "/tmp/${FONT_NAME}.zip" -d "$FONT_DIR"

        if [[ $? -ne 0 ]]; then
            echo "WARNING: Failed to extract fonts. Ensure 'unzip' is installed on your system."
        else
            # Clean up the zip file
            rm "/tmp/${FONT_NAME}.zip"

            # Refresh the font cache
            echo "Refreshing font cache..."
            fc-cache -fv "$FONT_DIR"

            if [[ $? -eq 0 ]]; then
                echo "$FONT_NAME Nerd Font installed successfully!"
            else
                echo "Font cache refresh failed. You may need to run 'fc-cache -fv' manually."
            fi
        fi
    fi
}



# ############################################# #
# SECTION 16 - Configuration and Tweaks

apply_setting() {
    "$@"
    if [ $? -ne 0 ]; then
        echo "WARNING: $1 failed to apply."
    fi
}

apply_gsetting() {
    local schema="$1"
    local key="$2"
    local value="$3"

    # Check if gsettings is available
    if ! command -v gsettings &>/dev/null; then
        echo "ERROR: gsettings is not installed or available in PATH."

    # Check if schema exists
    elif ! gsettings list-schemas | grep -q "^$schema$"; then
        echo "WARNING: Schema '$schema' not found. Skipping."

    # Check if key exists in the schema
    elif ! gsettings get "$schema" "$key" &>/dev/null; then
        echo "WARNING: Key '$key' not found in schema '$schema'. Skipping."

    else # Apply the setting
        apply_setting gsettings set "$schema" "$key" "$value"
        return 0
    fi

    # Return a non-zero status in case of failure
    return 1
}

# Check if tweaks exist first before enabling
apply_gnome_extension() {
    if gnome-extensions list | grep -q "$1"; then
        apply_setting gnome-extensions enable "$1"
    else
        echo "Extension $1 not found. Skipping."
    fi
}


# ······································ #
# GNOME Settings configuration:
# ······································ #

gsettings_conf() {
    echo -e "\nConfiguring GNOME Settings...\n"
    
    # Enable autologin for the user
    sudo sed -i "/^\[daemon\]$/a AutomaticLoginEnable=True\nAutomaticLogin=${USERNAME}" /etc/gdm/custom.conf


    # Set input language to Spanish and set as active:
    apply_gsetting org.gnome.desktop.input-sources sources "[('xkb', 'latam')]"

    # Set formats region to Argentina
    apply_gsetting org.gnome.system.locale region 'es_AR.UTF-8'


    # Enable automatic Date & Time
    sudo timedatectl set-ntp true  # Enable Network Time Protocol (NTP)

    # Show Weekdays
    apply_gsetting org.gnome.desktop.interface clock-show-weekday true

    # Set timezone to GMT-03 (Buenos Aires)
    apply_setting timedatectl set-timezone America/Argentina/Buenos_Aires


    # Night Light configuration:

    # Enable from 18:00 to 10:00
    apply_gsetting org.gnome.settings-daemon.plugins.color night-light-enabled true
    apply_gsetting org.gnome.settings-daemon.plugins.color night-light-schedule-from 18
    apply_gsetting org.gnome.settings-daemon.plugins.color night-light-schedule-to 10

    # Set temperature to 3500 (1/4th of the bar in GNOME Settings > Display > Night Light)
    apply_gsetting org.gnome.settings-daemon.plugins.color night-light-temperature 3500


    # Set audacious as default music player
    apply_setting xdg-mime default audacious.desktop audio/mpeg
    # Set Image Viewer as default photos app
    apply_setting xdg-mime default org.gnome.Loupe.desktop image/jpeg
}


# ······································ #
# GNOME Tweaks configuration:
# ······································ #

gtweaks_conf() {
    echo -e "\nConfiguring GNOME Tweaks...\n"

    # Set the GTK3 theme for legacy applications to Adwaita-dark
    apply_gsetting org.gnome.desktop.interface gtk-theme 'Adwaita-dark'

    # Enable maximize and minimize titlebar buttons
    apply_gsetting org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
    # Set Appearance > Style > Legacy Applications to 'Adwaita-dark'
    apply_gsetting org.gnome.desktop.interface gtk-theme 'Adwaita-dark'

    # Set cursor to Bibata-Modern-Ice
    apply_gsetting org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'

    # Set icons to Papirus
    apply_gsetting org.gnome.desktop.interface icon-theme 'Papirus'

    # Set the font for GNOME Console
    apply_gsetting org.gnome.desktop.interface monospace-font-theme 'CaskaydiaCove Nerd Font Regular'
}


# ······································ #
# GNOME Extensions configuration:
# ······································ #

gxt_conf() {
    echo -e "\nConfiguring GNOME Extensions...\n"

    # Enable extensions
    apply_gnome_extension "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
    apply_gnome_extension "light-style@gnome-shell-extensions.gcampax.github.com"
    apply_gnome_extension "user-theme@gnome-shell-extensions.gcampax.github.com"
}


# ······································ #
# GNOME Clocks configuration:
# ······································ #

gclocks_conf() {
    echo -e "\nConfiguring GNOME Clocks...\n"

    apply_gsetting org.gnome.clocks world-clocks "[{'location': <(uint32 2, <('Buenos Aires', 'SADP', true, [(-0.60388392119003798, -1.0227629416686772)], [(-0.6036657550335387, -1.024028305376373)])>)>}]"

    # Check if GNOME Clocks is running
    if pgrep -x "gnome-clocks" > /dev/null; then
        echo "GNOME Clocks is running. Restarting..."
        pkill gnome-clocks
    fi

    # Start GNOME Clocks, wait for it to initialize, then close it
    gnome-clocks &
    sleep 2 # Adjust the delay if needed for the app to fully initialize
    pkill gnome-clocks

    echo "GNOME Clocks restarted and closed."
}


# ······································ #
# GNOME Console configuration:
# ······································ #

gconsole_conf() {
    echo -e "\nConfiguring GNOME Console...\n"

    # Set background transparency level (10-30 for subtle translucency)
    local TRANSPARENCY=30

    echo "Setting GNOME Console transparency to $TRANSPARENCY%..."

    dconf write /org/gnome/Console/transparency $TRANSPARENCY

    # Verify changes
    if [[ $? -eq 0 ]]; then
        echo "Transparency successfully configured in GNOME Console."
    else
        echo "Failed to configure transparency in GNOME Console."
    fi
}


# ······································ #
# Audacious configuration:
# ······································ #

audacious_conf() {
    echo -e "\nConfiguring Audacious...\n"

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

        local MUSIC_LIB="${TB_MOUNTPOINT}/Franco/3. Música/1. Biblioteca de Música"

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
automatic=FALSE
length=1
manual_length=1.5
no_fade_in=TRUE

[qtui]
column_widths=25,55,427,277,44,267,175,25,100,41,59,275,275,275,75,275,175,75
player_height=1011
player_width=1920
playlist_columns=playing number artist title album length year queued
playlist_headers_bold=TRUE

[search-tool]
monitor=TRUE
path=${MUSIC_LIB}
rescan_on_startup=TRUE

[skins]
skin=/usr/share/audacious/Skins/Default

[skins-layout]
lyrics-qt=13,32,288,192
search-tool-qt=13,32,288,192
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
}


# ······································ #
# Other configurations:
# ······································ #

misc_conf() {
    echo -e "\nConfiguring miscellaneous things...\n"

    # Create music directories in the home music folder
    mkdir -p "$HOME/Music/NEW"
    mkdir -p "$HOME/Music/OLD"
    mkdir -p "$HOME/Music/READY"

    TB_MOUNTPOINT="/mnt/1TB"

    # Define the paths as variables
    local MUSIC_PATH="$HOME/Music/NEW"
    local YT_DLP_PATH="$TB_MOUNTPOINT/Franco/3. Música/0-yt-dlp"
    local TO_DOWNLOAD_PATH="$YT_DLP_PATH/WISHLIST.txt"
    local DOWNLOADED_PATH="$YT_DLP_PATH/ARCHIVE.txt"

    # Use cat and EOF to append the aliases to /etc/bash.bashrc
    cat << EOF | sudo tee -a /etc/bash.bashrc > /dev/null


# ################################################ #

# USER'S MUSIC ALIASES
# Employs yt-dlp

# WHAT THEY ALL DO:
# Download video in best audio quality,
# extract audio,
# convert to mp3
# Embed metadata

# Download a single track:
alias getMusic="yt-dlp -x --audio-format mp3 --embed-metadata -P \"$MUSIC_PATH\" -o \"%(artist)s - %(title)s.%(ext)s\""

# Download several tracks in batch from a file and archive it in another file
alias getMusicList="yt-dlp -x --audio-format mp3 --embed-metadata -P \"$MUSIC_PATH\" -o \"%(artist)s - %(title)s.%(ext)s\" -a \"$TO_DOWNLOAD_PATH\" --download-archive \"$DOWNLOADED_PATH\""
EOF

    echo -e "\nyt-dlp aliases set...\n"
}



# ############################################# #
# SECTION 17 - Cleanup and Debloat

debloat_gnome() {
    clear
    echo -e "\nDebloating GNOME...\n"

    # Remove unnecessary gnome apps (for me)
    local PACKAGES="gnome-contacts gnome-maps gnome-music \
                    gnome-user-docs gnome-calendar gnome-text-editor \
                    gnome-weather gnome-tour gnome-system-monitor \
                    gnome-connections gnome-font-viewer evince sushi \
                    totem malcontent epiphany yelp snapshot"

    if sudo pacman -R $PACKAGES --noconfirm; then
        echo -e "\nGNOME successfully debloated!\n"
    else
        echo -e "\nWARNING: could not remove these GNOME packages:\n\n$PACKAGES\n\n"
    fi

    local GXT_PATH='/usr/share/applications/org.gnome.Extensions.desktop'
    local GXT_HIDE_PROPERTY='NoDisplay=true'
    if ! grep -q "${GXT_HIDE_PROPERTY}" "${GXT_PATH}"; then
        # Hide GNOME extensions
        sudo sh -c "echo ${GXT_HIDE_PROPERTY} >> ${GXT_PATH}"
    fi
}

gen_todo() {
    echo -e "\nGenerating to-do list...\n"

    # Define the output file path
    local TODO_PATH="$HOME/Documents/postInstall_todo.txt"
    local TEMP_PATH="$TODO_PATH.tmp"

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

Visual Studio Code (optional):
    - Sign in with your GitHub user to sync your settings.
    - Add your GitHub username and email for committing.
        In the VS Code's terminal, execute these commands:
        git config -–global user.name your-user-name
        git config -–global user.email your-email

Others:
    - Open Firefox and log into necessary accounts
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
}

rm_tmp_file() {
    echo -e "\nDeleting temp_vars.sh...\n"

    # Remove temporary file used for the scripts
    sudo rm -f "$HOME/temp_vars.sh" || echo "Warning: temp_vars.sh could not be deleted."
}

rm_self() {
    echo -e "\nDeleting this file...\n"

    # Delete this script
    sudo rm -f -- "$0" || echo "Warning: $0 couldn't be deleted."
}

rm_sudo_paswordless() {
    echo -e "\nRestoring sudoers configuration...\n"

    # Remove the passwordless sudo rule from sudoers
    sudo EDITOR='sed -i "/^${USERNAME} ALL=(ALL) NOPASSWD: ALL$/d"' visudo
}

rm_script_mods() {
    echo -e "\nRemoving .bashrc modifications for executing this script...\n"

    # Remove .bashrc modifications for script execution
    sed -i '/archInstall_3.sh/,/fi/d' "$HOME/.bashrc"
    cat "$HOME/.bashrc" & sleep 3
}


help() {
    cat << EOF

Usage: $0 [option]

Options:
    all | no option     Run the entire script (default)
    grub                Updates GRUB to recognize other OS
    wifi                Connects to wifi
    disk                Mounts the 1TB disk
    aur                 Sets up the AUR repository
    install-pkgs        Installs:
                            - VSCode
                            - Webcord
                            - DroidCam
                            - Bibata cursor themes
                            - Papirus icon themes
                            - CascadiaCode console font
    gnome-cfg           Configures GNOME:
                            - Settings
                            - Tweaks
                            - Extensions
                            - Console
    audacious-cfg       Configures Audacious
    misc-cfg            Currently, sets up global aliases for yt-dlp
    gnome-debloat       Removes some unused GNOME packages (you can install them back if you want to)
    finish              USE ONLY WHEN DONE WITH THIS SCRIPT

    help                Display this message

EOF
}


case "$1" in
    all|"")
        import_variables
        grub_update
        wifi_setup
        mount_disk

        aur_setup
        vscode
        webcord
        droidcam
        bibata
        papirus
        cascadia_font

        gsettings_conf
        gtweaks_conf
        gxt_conf
        gclocks_conf
        gconsole_conf
        audacious_conf
        misc_conf

        debloat_gnome
        gen_todo
        rm_tmp_file
        rm_self
        rm_sudo_paswordless
        rm_script_mods
        ;;

    grub)
        grub_update
        ;;
    wifi)
        import_variables
        wifi_setup
        ;;
    disk)
        mount_disk
        ;;
    aur)
        import_variables
        wifi_setup
        aur_setup
        ;;
    install-pkgs)
        import_variables
        wifi_setup

        aur_setup

        vscode
        webcord
        droidcam
        bibata
        papirus
        cascadia_font
        ;;
    gnome-cfg)
        import_variables

        gsettings_conf
        gtweaks_conf
        gxt_conf
        gclocks_conf
        gconsole_conf
        ;;
    audacious-cfg)
        mount_disk
        audacious_conf
        ;;
    misc-cfg)
        misc_conf
        ;;
    gnome-debloat)
        debloat_gnome
        ;;
    finish)
        gen_todo
        rm_tmp_file
        rm_self
        rm_sudo_paswordless
        rm_script_mods
        ;;

    help)
        help
        ;;
    *)
        echo -e "\nERROR: invalid option.\n"
        ;;
    
esac



# Exit the script
exit 0


# ############################################# #
#               END OF THE SCRIPT
# ############################################# #
