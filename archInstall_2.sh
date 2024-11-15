#!/usr/bin/bash
# Fran's Arch Linux Automated Installation Script (part 2)

# ############################################# #
# Import variables from part 1

clear
echo -e "\nImporting data...\n"
if [ ! -f /temp_vars.sh ]; then
    echo "Error: Data file /temp_vars.sh not found. Could not import data."
    exit 1
fi

source /temp_vars.sh



# ############################################# #
# SECTION 10 - Setting up users

clear
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

clear
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

clear
# Store packages in groups in a variable
# for easier readability
PACKAGES="base-devel \
grub efibootmgr \
linux linux-firmware linux-headers linux-lts linux-lts-headers \
lvm2 \
nvidia nvidia-utils nvidia-lts \
networkmanager bluez blueman bluez-utils \
dosfstools mtools os-prober sudo \
gparted htop man neofetch \
gnome gnome-tweaks gnome-themes-extra"

# Perform the installation (enjoy!)
if ! pacman -S ${PACKAGES} --noconfirm --needed; then
  echo "Error installing packages. Exiting..."
  exit 1
fi
echo "Needed system packages installed."



# ############################################# #
# SECTION 13 - Generating RAM Disk(s) for our Kernel(s)

clear
# Edit mkcpio config file for our encryption to work
sed -i "s/^HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block/& encrypt lvm2/" /etc/mkinitcpio.conf

# Generate initramfs for each of the previously installed kernels:
mkinitcpio -p linux
mkinitcpio -p linux-lts



# ############################################# #
# SECTION 14 - Post-Installation (misc.) Setup

clear
# Set locales
sed -i "s/^#en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen
sed -i "s/^#es_AR.UTF-8/es_AR.UTF-8/" /etc/locale.gen

# Generate locales
locale-gen

# Show existing locale.conf (if any) for reference
clear
echo -e "Before adding locale custom settings:\n\n"
cat /etc/locale.conf || echo "No existing /etc/locale.conf file."
read -p "Press enter to continue..."

# Add custom settings to the locale config file
cat << EOF > /etc/locale.conf
LANG=en_US.UTF-8
LC_NUMERIC=es_AR.UTF-8
LC_TIME=es_AR.UTF-8
LC_MONETARY=es_AR.UTF-8
LC_PAPER=es_AR.UTF-8
LC_MEASUREMENT=es_AR.UTF-8
EOF

# Show the updated /etc/locale.conf
clear
echo -e "\n\nAfter adding locale custom settings:\n\n"
cat /etc/locale.conf
read -p "Press enter to continue..."

clear
# Add our encrypted volume to the GRUB config file
sed -i "s,GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3,& cryptdevice=${SYS_DISK}4:volgroup0," /etc/default/grub

# Enabling os-prober to detect multi-os systems in GRUB:
sed -i "s/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/" /etc/default/grub

# Define the expected line for verification
EXPECTED="GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 cryptdevice=${SYS_DISK}4:volgroup0 quiet\""

# Verify that the line matches exactly as expected
if ! grep -q "^${EXPECTED}$" /etc/default/grub; then
    clear
    echo "Error: GRUB_CMDLINE_LINUX_DEFAULT line was not updated correctly."
    exit 1
fi

# Mount EFI partition (the 1st we created)
mount --mkdir "${SYS_DISK}1" /boot/EFI

# Check if the partition was successfully mounted
if ! mount | grep -q "/boot/EFI"; then
  echo "ERROR: EFI partition couldn't be mounted!"
  exit 1
fi

clear
# Install GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=Arch_btw --recheck

# Copy grub locale file into our directory
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo

clear
# Make grub config
grub-mkconfig -o /boot/grub/grub.cfg

clear
# Grant the newly created user sudo privileges
echo '%wheel ALL=(ALL) ALL' | EDITOR='tee -a' visudo

if grep '# %wheel ALL=(ALL) ALL' /etc/sudoers; then
  clear
  echo "ERROR: couldn't grant sudo privileges to $USERNAME."
  read -p "Press enter to continue..."
fi

clear
# Enable GNOME greeter
systemctl enable gdm

# Enable wifi
systemctl enable NetworkManager

# Enable bluetooth
modprobe btusb
systemctl enable bluetooth
systemctl start bluetooth

clear
# Install rest of the packages
PACKAGES="firefox \
rhythmbox audacious \
reaper easytag qjackctl \
gimp krita obs-studio \
nano vim libreoffice-fresh \
yt-dlp"
if ! pacman -Syu ${PACKAGES} --noconfirm --needed; then
    clear
    echo "Error installing packages. Exiting..."
    exit 1
fi

clear
# Install remaining packages
PACKAGES="com.mattjakeman.ExtensionManager \
com.discordapp.Discord \
org.gtk.Gtk3theme.Adwaita-dark \
org.musicbrainz.Picard"
flatpak install flathub $PACKAGES -y



clear
echo "Downloading the third part of the setup script..."

# fetch the 3rd part of the script into the installation
curl -o /archInstall_3.sh https://raw.githubusercontent.com/FrancoSosaZ0206/MyArchInstallScript/main/archInstall_3.sh
chmod +x /archInstall_3.sh


clear
# Print checkout message
echo -e "\nInstallation complete! Run:\n\n \
umount -R /mnt\n \
reboot\n\n \
After booting into the new system, Run:\n\n \
archInstall_3.sh\n\n \
to perform some post-installation tweaks.\n \
Enjoy your new Arch Linux System! :)\n\n"

# Cleanup - Delete this script
rm -- "$0"
# Exit the installation, stopping this script
exit 0
