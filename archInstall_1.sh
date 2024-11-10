#!/bin/bash
# Fran's Arch Linux Automated Installation Script

# This script is structured in sections,
# Which reflect the installation order and steps.


# ############################################# #
#                   VARIABLES
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

# Clean the screen
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

# Clean the screen
clear
# confirm changes by showing them to the user,
# and wait for him to press enter after each of these commands
vgdisplay
read -p "Press Enter to continue..."
clear
lvdisplay
read -p "Press Enter to continue..."

# Clean the screen
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

# Clean the screen
clear
# Show user the results
cat /mnt/etc/fstab
# Pause until user has read and presses enter
read -p "Press Enter to continue..."



# ############################################# #
# SECTION 9 - Chroot into the installation

# Clean the screen
clear

echo "Downloading the second part of the setup script..."

# fetch the 2nd part of the script into the installation
curl -o /mnt/archInstall_2.sh https://github.com/FrancoSosaZ0206/MyArchInstallScript/main/archInstall_2.sh
chmod +x /mnt/archInstall_2.sh

# Clean the screen
clear

echo "Entering chroot environment. Run ./archInstall_2.sh to finish setup."

# Export common variables to a temporary file:
{
    echo "INSTALLATION_ROOT_PASSWD=${INSTALLATION_ROOT_PASSWD}"
    echo "USERNAME=${USERNAME}"
    echo "USER_PASSWD=${USER_PASSWD}"
    echo "DISK=${DISK}"
} >> /mnt/temp_vars.sh

# make temp_vars.sh readable only by root user
chmod 600 /mnt/temp_vars.sh

# chroot into the installation
arch-chroot /mnt

# ############################################# #
# Continued in part 2!
