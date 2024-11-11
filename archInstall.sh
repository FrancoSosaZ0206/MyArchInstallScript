#!/bin/bash
# Fran's Arch Linux Automated Installation Script

# This script is structured in sections,
# Which reflect the installation order and steps.


# ############################################# #
#                   GLOBAL VARIABLES
# ############################################# #

DISK=""
INSTALLER_ROOT_PASSWD=""
INSTALLATION_ROOT_PASSWD=""
LVM_PASSWD=""

USERNAME=""
USER_PASSWD=""

WIFI_SSID=""
WIFI_PASSWD=""

KEYMAP=""
TIMEZONE=""



# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #

# PART 1

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #



# ############################################# #
# SECTION 1 - Pre-Installation (misc.) Setup

# Set a bigger font for better readability.
setfont ter-132b

# Prompt user to select a keyboard imput
read -p "Enter the keyboard layout (e.g., 'us', 'es', etc.): " KEYMAP
# Loads selected keyboard input
loadkeys "${KEYMAP}"

# Prompt the user to input wifi information
read -p "Enter the WiFi SSID (network name): " WIFI_SSID
read -sp "Enter the WiFi passphrase: " WIFI_PASSWD
echo
# Connect to wifi (if ethernet connection is available, skip this step)
iwctl --passphrase "${WIFI_PASSWD}" station wlan0 connect "${WIFI_SSID}"

# Prompt the user to select their local timezone (helps with mirrors)
read -p "Enter your timezone (e.g., 'America/New_York'): " TIMEZONE
# Set local timezone
timedatectl set-timezone "${TIMEZONE}"

# Prompt user to set a root password for the installation media
read -sp "Enter installation media's root password: " INSTALLER_ROOT_PASSWD
echo
# Set this installer's root password
echo "root:${INSTALLER_ROOT_PASSWD}" | chpasswd

# Disk encryption passphrase
read -sp "Enter the encryption passphrase for the disk: " LVM_PASSWD
echo

# Installation's root password
read -sp "Enter the root password for the new installation: " INSTALLATION_ROOT_PASSWD
echo

# Username and password for the new user
read -p "Enter the installation's username: " USERNAME
read -sp "Enter the password for $USERNAME: " USER_PASSWD
echo




# --------------------------------------------- #
#               INSTALLATION PART
# --------------------------------------------- #


# ############################################# #
# SECTION 2 - Disk Partitioning
# If you wanna keep your current partition layout, skip this step.

# Layout:
# 1° - 1GB - Linux Filesystem - /boot/EFI (WARNING: mount in section X, not section 3!)
# 2° - 1GB - Linux Filesystem - /boot
# 3° - 4GB - Linux Filesystem - SWAP partition

# 4° - [rest of the disk] - Linux LVM (/ and /home will be inside here)
#    volgroup0:
#       lv_root - 50GB
#       lv_home - Rest of the disk

# Start the partitioning
# -s, --script option allows to run parted from script automatedly.

# Clear the screen
clear
# Print disk layout
lsblk
# Prompt user to select a disk
read -p "Enter the disk (e.g., 'sdb' for /dev/sdb): " DISK
DISK="/dev/$DISK"  # Prepend with /dev

# Create a new partition table
parted -s "${DISK}" mklabel gpt

# Partitions:

# 1° - EFI, 1GB
parted -s "${DISK}" mkpart ESP fat32 1MiB 1GiB
# Set 1st partition as bootable
parted -s "${DISK}" set 1 boot on

# 2° - /boot, 1GB
parted -s "${DISK}" mkpart primary ext4 1GiB 2GiB
# 3° - swap, 4GB
parted -s "${DISK}" mkpart primary linux-swap 2GiB 6Gib

# 4° - LVM, rest of the disk
parted -s "${DISK}" mkpart primary ext4 6GiB 100%
# Set 4th partition as lvm
parted -s "${DISK}" set 4 lvm on

# Print partition table for verification
parted -s "${DISK}" print


# ############################################# #
# SECTION 3 - Partition Formatting

mkfs.fat -F32 "${DISK}1"     # EFI partition
mkfs.ext4 "${DISK}2"         # /boot partition
mkswap "${DISK}3"            # swap partition

# sdb4 will be formatted later (see section X).

# ############################################# #
# SECTION 4 - Setting up an encrypted partition

# Encrypting the partition and setting the passphrase automatically
# --batch-mode avoids the "YES" confirmation prompt
echo -n "${LVM_PASSWD}" | cryptsetup luksFormat --batch-mode "${DISK}4" -
echo -n "${LVM_PASSWD}" | cryptsetup open --type luks "${DISK}4" lvm -

# ############################################# #
# SECTION 5 - Configuring LVM

# Create a physical volume
pvcreate /dev/mapper/lvm

# Create a volume group
vgcreate volgroup0 /dev/mapper/lvm

# Create the logical volumes
lvcreate -L 50GB volgroup0 -n lv_root   # root volume (50GB is more than enough to fill our system with programs)
lvcreate -l 100%FREE volgroup0 -n lv_home  # home vol. (rest of the disk)

# Clear the screen
clear
# confirm changes by showing them to the user,
# and wait for him to press enter after each of these commands
vgdisplay
read -p "Press Enter to continue..."
clear
lvdisplay
read -p "Press Enter to continue..."

# Clear the screen
clear
# Insert a kernel module
modprobe dm_mod
vgscan
read -p "Press Enter to continue..."
vgchange -ay

# Format the encrypted partitions
mkfs.ext4 /dev/volgroup0/lv_root
mkfs.ext4 /dev/volgroup0/lv_home



# ############################################# #
# SECTION 6 - Partition Mounting

# Mount root partition
mount /dev/volgroup0/lv_root /mnt

# Mount boot (2nd) partition
mount --mkdir "${DISK}2" /mnt/boot

# Mount home partition
mount --mkdir /dev/volgroup0/lv_home /mnt/home

# Turn on swap partition
swapon "${DISK}3"



# ############################################# #
# SECTION 7 - Installing the base system

pacstrap /mnt base --noconfirm --needed

# ############################################# #
# SECTION 8 - Generate fstab file

# Generate the file:
genfstab -U -p /mnt >> /mnt/etc/fstab

# Clear the screen
clear
# Show user the results
cat /mnt/etc/fstab
# Pause until user has read and presses enter
read -p "Press Enter to continue..."



# ############################################# #
# SECTION 9 - Chroot into the installation

# clear
#echo "Downloading the second part of the setup script..."

# fetch the 2nd part of the script into the installation
#curl -o /mnt/archInstall_2.sh https://raw.githubusercontent.com/FrancoSosaZ0206/MyArchInstallScript/main/archInstall_2.sh
#chmod +x /mnt/archInstall_2.sh

#ls /mnt/

clear
echo "Entering chroot environment..." #... Run ./archInstall_2.sh to finish setup."
read -p "Press Enter to continue..."

# Export common variables to a temporary file:
# {
#     echo "INSTALLATION_ROOT_PASSWD=${INSTALLATION_ROOT_PASSWD}"
#     echo "USERNAME=${USERNAME}"
#     echo "USER_PASSWD=${USER_PASSWD}"
#     echo "DISK=${DISK}"
# } >> /mnt/temp_vars.sh




# chroot into the installation and run part 2
arch-chroot /mnt /bin/bash -c "$(tail -n +$(grep -n "^# PART 2" "$0" | cut -d: -f1) "$0")"

exit 0













# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #

# PART 2

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #












# vvvvvvvvvvvvvvvvvDEPRECATEDvvvvvvvvvvvvvvvvvv #
# ############################################# #
# Import variables from part 1

# echo -e "\nImporting data...\n"
# if [ ! -f /temp_vars.sh ]; then
#     echo "Error: Data file /temp_vars.sh not found. Could not import data."
#     exit 1
# fi
# 
# echo -e "\nData file found!\n"
# source /temp_vars.sh
# read -p "Data imported. Press Enter to continue..."
# ^^^^^^^^^^^^^^^^^^DEPRECATED^^^^^^^^^^^^^^^^^^ #



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
sed -i "s/^HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block /& encrypt lvm2/" /etc/mkinitcpio.conf

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

# Add our encrypted volume to the GRUB config file
sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3/& cryptdevice=${DISK}4:volgroup0/" /etc/default/grub

# Enabling os-prober to detect multi-os systems in GRUB:
sed -i "s/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/" /etc/default/grub

clear
# confirm changes
less /etc/default/grub

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
# rm /temp_vars.sh

# if [ -f /temp_vars.sh ]; then
#     echo "Warning: temp_vars.sh could not be deleted."
# else
#     echo "Temporary file temp_vars.sh successfully deleted."
# fi


# Clear the screen
clear
# Print checkout message
echo -e "\nInstallation complete! Run:\n\numount -a\nreboot\n\nEnjoy your new Arch Linux System! :)"

# Exit the installation, stopping this script
exit 0
