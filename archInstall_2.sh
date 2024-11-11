#!/usr/bin/bash
# Fran's Arch Linux Automated Installation Script (part 2)

# ############################################# #
# Import variables from part 1

echo -e "\nImporting data...\n"
if [ ! -f /temp_vars.sh ]; then
    echo "Error: Data file /temp_vars.sh not found. Could not import data."
    exit 1
fi

echo -e "\nData file found!\n"
source /temp_vars.sh
read -p "Data imported. Press Enter to continue..."



# ############################################# #
# SECTION 10 - Setting up users

# Set installation's root password
echo "Setting up root password..."
echo "root:${INSTALLATION_ROOT_PASSWD}" | chpasswd
read -p "Press Enter to continue..."


# Create a new user (if it doesn't exist)
echo "Creating user..."
id -u "${USERNAME}" &>/dev/null || useradd -m -g users -G wheel -s /bin/bash "${USERNAME}"

# Set user's password
# for simplicity's sake,
# it'll be the same as root for now.
echo "${USERNAME}:${USER_PASSWD}" | chpasswd

# Confirm that the user exists by listing all users
echo -e "\nUsers on the system:"
cut -d: -f1 /etc/passwd | grep -E "^root|^${USERNAME}"
read -p "Press Enter to continue..."


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

# output modified lines for confirmation:
echo -e "\nConfirming pacman config changes:"
grep -E "^(Color|ParallelDownloads|ILoveCandy)" /etc/pacman.conf
read -p "Press Enter to continue..."

# Update pacman before proceeding:
pacman -Sy --noconfirm

echo -e "\nPacman optimized!\n"
read -p "Press Enter to continue..."


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
echo "Packages installed successfully."
read -p "Press Enter to continue..."

# install later (with pacman):
# pacman -S "firefox rhythmbox reaper easytag picard qjackctl \
#          gimp krita obs-studio \
#          nano vim libreoffice-fresh" --noconfirm --needed

# left to install (via flathub and AUR):
# vs-code (visual-studio-code-bin) (using yay)
# extension manager (better than GNOME's extensions) (flatpak, better to just install it through GNOME Software)
# DaVinci Resolve


# ############################################# #
# SECTION 13 - Generating RAM Disk(s) for our Kernel(s)

# Edit mkcpio config file for our encryption to work
sed -i "s/^HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block/& encrypt lvm2 /" /etc/mkinitcpio.conf

clean
# confirm changes
less /etc/mkinitcpio.conf

# Generate initramfs for each of the previously installed kernels:
mkinitcpio -p linux
mkinitcpio -p linux-lts



# ############################################# #
# SECTION 14 - Post-Installation (misc.) Setup

# Set locales
sed -i "s/^#en_US.UTF-8/en_US.UTF-8/" /etc/locale.gen
sed -i "s/^#es_AR.UTF-8/es_AR.UTF-8/" /etc/locale.gen

clear
# confirm changes
less /etc/locale.gen

# Generate locales
locale-gen

echo -e "\nBefore editing grub:\n\n"
tail /etc/default/grub
read -p "Press enter to continue..."

# Add our encrypted volume to the GRUB config file
sed -i "s,GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 ,GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 cryptdevice=${DISK}4:volgroup0 ,g" /etc/default/grub

# Enabling os-prober to detect multi-os systems in GRUB:
sed -i "s/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/" /etc/default/grub

echo -e "\nAfter editing grub:\n\n"
tail /etc/default/grub
read -p "Press enter to continue..."

# Define the expected line for verification
EXPECTED="GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 cryptdevice=${DISK}4:volgroup0 quiet\""

# Verify that the line matches exactly as expected
if ! grep -q "^${EXPECTED}$" /etc/default/grub; then
    echo "Error: GRUB_CMDLINE_LINUX_DEFAULT line was not updated correctly."
    exit 1
fi

# clear
# confirm changes
# less /etc/default/grub

# Mount EFI partition (the 1st we created)
mount --mkdir "${DISK}1" /boot/EFI

# Install GRUB
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck

# Copy grub locale file into our directory
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo

# Make grub config
grub-mkconfig -o /boot/grub/grub.cfg

# Grant the newly created user super user (sudo) privileges
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

clear
# confirm changes
less /etc/sudoers

# Enable GNOME greeter
systemctl enable gdm

# Enable wifi
systemctl enable NetworkManager

# Cleanup
rm /temp_vars.sh

if [ -f /temp_vars.sh ]; then
    echo "Warning: temp_vars.sh could not be deleted."
else
    echo "Temporary file temp_vars.sh successfully deleted."
fi


# Clear the screen
clear
# Print checkout message
echo -e "\nInstallation complete! Run:\n\numount -a\nreboot\n\nEnjoy your new Arch Linux System! :)"

# Exit the installation, stopping this script
exit 0
