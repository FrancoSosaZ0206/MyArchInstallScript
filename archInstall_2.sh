#!/usr/bin/bash
# Fran's Arch Linux Automated Installation Script (part 2)

# ############################################# #
# Import variables from part 1

echo -e "\nImporting data...\n"
if [ ! -f /temp_vars.sh ]; then
    echo "Error: Data file /temp_vars.sh not found. Could not import data."
    exit 1
fi

source /temp_vars.sh



# ############################################# #
# SECTION 10 - Setting up users

# Set installation's root password
echo "root:${INSTALLATION_ROOT_PASSWD}" | chpasswd


# Create a new user (if it doesn't exist)
id -u "${USERNAME}" &>/dev/null || useradd -m -g users -G wheel -s /bin/bash "${USERNAME}"

# Set user's password
# for simplicity's sake,
# it'll be the same as root for now.
echo "${USERNAME}:${USER_PASSWD}" | chpasswd



# ############################################# #
# SECTION 11 - Configure & Speed Up Pacman
# This will save a TON of time when downloading
# all the packages.

# Enable colored output
sed -i "s/^#Color/Color/" /etc/pacman.conf

# Enable parallel downloads
sed -i "s/^#ParallelDownloads/ParallelDownloads/" /etc/pacman.conf

# Add ILoveCandy to the misc options for some extra fun
sed -i "/^#DisableSandbox/a ILoveCandy" /etc/pacman.conf
# Super important, of course.
# Mhm.
# Totally needed.

# Update pacman before proceeding:
pacman -Sy --noconfirm



# ############################################# #
# SECTION 12 - Install All The Packages

# Store packages in groups in a variable
# for easier readability
PACKAGES="base-devel \
          grub efibootmgr \
          linux linux-firmware linux-headers linux-lts linux-lts-headers \
          lvm2 \
          nvidia nvidia-utils nvidia-lts \
          gnome gnome-tweaks gnome-themes-extra \
          networkmanager bluez blueman bluez-utils \
          dosfstools mtools os-prober sudo \
          gparted htop man neofetch"

# Perform the installation (enjoy!)
if ! pacman -Syu ${PACKAGES} --noconfirm --needed; then
  echo "Error installing packages. Exiting..."
  exit 1
fi



# ############################################# #
# SECTION 13 - Generating RAM Disk(s) for our Kernel(s)

# Edit mkcpio config file for our encryption to work
sed -i "s/^HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block/& encrypt lvm2/" /etc/mkinitcpio.conf

clear

# Generate initramfs for each of the previously installed kernels:
mkinitcpio -p linux
mkinitcpio -p linux-lts



# ############################################# #
# SECTION 14 - Post-Installation (misc.) Setup

# Set locales
sed -i "s/^#en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen
sed -i "s/^#es_AR.UTF-8/es_AR.UTF-8/" /etc/locale.gen

clear

# Generate locales
locale-gen

# Add our encrypted volume to the GRUB config file
sed -i "s,GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 ,GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 cryptdevice=${DISK}4:volgroup0 ," /etc/default/grub

# Enabling os-prober to detect multi-os systems in GRUB:
sed -i "s/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/" /etc/default/grub

# Define the expected line for verification
EXPECTED="GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 cryptdevice=${DISK}4:volgroup0 quiet\""

# Verify that the line matches exactly as expected
if ! grep -q "^${EXPECTED}$" /etc/default/grub; then
    echo "Error: GRUB_CMDLINE_LINUX_DEFAULT line was not updated correctly."
    exit 1
fi

# Mount EFI partition (the 1st we created)
mount --mkdir "${DISK}1" /boot/EFI

# Install GRUB
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck

# Copy grub locale file into our directory
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo

# Make grub config
grub-mkconfig -o /boot/grub/grub.cfg

# Grant the newly created user sudo privileges
sudo sed -i "s/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/" /etc/sudoers

if grep '# %wheel ALL=(ALL) ALL' /etc/sudoers; then
  clear
  echo "ERROR: couldn't grant sudo privileges to $USERNAME."
  read -p "Press enter to continue..."
fi

# Enable GNOME greeter
systemctl enable gdm

# Enable wifi
systemctl enable NetworkManager

# Install rest of the packages
PACKAGES="firefox rhythmbox reaper easytag picard qjackctl \
         gimp krita obs-studio \
         nano vim libreoffice-fresh \
         yt-dlp"
if ! pacman -Syu ${PACKAGES} --noconfirm --needed; then
  echo "Error installing packages. Exiting..."
  exit 1
fi

# ADD THE AUR REPOSITORY (with yay)
# Install prerequisites for building AUR packages
sudo pacman -S git --needed --noconfirm

# Clone the yay repository
git clone https://aur.archlinux.org/yay.git /yay

# Navigate to the yay directory and install yay
cd /yay
makepkg -si --noconfirm

# Install remaining packages through yay and flatpak
yay -S visual-studio-code-bin

# if vs code can't be installed with yay, do it with flatpak
if ! yay -Qs visual-studio-code-bin > /dev/null; then
  flatpak install flathub com.visualstudio.code -y
fi

yay -S davinci-resolve
flatpak install flathub com.mattjakeman.ExtensionManager com.discordapp.Discord org.gtk.Gtk3theme.Adwaita-dark -y

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



# Cleanup unnecessary gnome apps (for me)
PACKAGES="gnome-contacts gnome-maps gnome-music \
        gnome-weather gnome-tour gnome-system-monitor \
        yelp totem malcontent"
pacman -Rns $PACKAGES --noconfirm

# Cleanup temporary file
rm /temp_vars.sh

if [ -f /temp_vars.sh ]; then
    echo "Warning: temp_vars.sh could not be deleted."
fi


# Clear the screen
clear
# Print checkout message
echo -e "\nInstallation complete! Run:\n\numount -a\nreboot\n\nEnjoy your new Arch Linux System! :)"

# Exit the installation, stopping this script
exit 0
