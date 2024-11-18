#!/bin/bash
# Fran's Arch Linux Automated Installation Script (part 1)

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
# read -p "Enter the keyboard layout (e.g., 'us', 'es', etc.): " KEYMAP
# Loads selected keyboard input
loadkeys "${KEYMAP}"

# Check if the device is already connected to a network (Wi-Fi/Ethernet)
while ! ip addr show | grep -q "state UP"; do
    # Prompt the user to input Wi-Fi information
    # read -p "Enter the Wi-Fi SSID (network name): " WIFI_SSID
    # read -sp "Enter the Wi-Fi passphrase: " WIFI_PASSWD
    # echo
    
    # Connect to Wi-Fi
    iwctl --passphrase "${WIFI_PASSWD}" station wlan0 connect "${WIFI_SSID}"

    # If connection wasn't successful
    if  ! ip addr show | grep -q "state UP"; then
        echo "Failed to connect. Please check the SSID and password and try again."
    else
        echo "Successfully connected to $WIFI_SSID."
    fi
done

# Prompt the user to select their local timezone (helps with mirrors)
# read -p "Enter your timezone (e.g., 'America/New_York'): " TIMEZONE
# Set local timezone
timedatectl set-timezone "${TIMEZONE}"

# Prompt user to set a root password for the installation media
# read -sp "Enter installation media's root password: " INSTALLER_ROOT_PASSWD
# echo
# Set this installer's root password
echo "root:${INSTALLER_ROOT_PASSWD}" | chpasswd

# Disk encryption passphrase
# read -sp "Enter the encryption passphrase for the disk: " LVM_PASSWD
# echo

# Installation's root password
# read -sp "Enter the root password for the new installation: " INSTALLATION_ROOT_PASSWD
# echo

# Username and password for the new user
# read -p "Enter the installation's username: " USERNAME
# read -sp "Enter the password for $USERNAME: " USER_PASSWD
# echo



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
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
# Prompt user to select a disk
read -p "Enter the disk (e.g., 'sdb' for /dev/sdb) where the system will be: " SYS_DISK
SYS_DISK="/dev/$SYS_DISK"  # Prepend with /dev

# Create a new partition table
parted -s "${SYS_DISK}" mklabel gpt

# Partitions:

# 1° - EFI, 1GB
parted -s "${SYS_DISK}" mkpart ESP fat32 1MiB 1GiB
# Set 1st partition as bootable
parted -s "${SYS_DISK}" set 1 boot on

# 2° - /boot, 1GB
parted -s "${SYS_DISK}" mkpart primary ext4 1GiB 2GiB
# 3° - swap, 4GB
parted -s "${SYS_DISK}" mkpart primary linux-swap 2GiB 6Gib

# 4° - LVM, rest of the disk
parted -s "${SYS_DISK}" mkpart primary ext4 6GiB 100%
# Set 4th partition as lvm
parted -s "${SYS_DISK}" set 4 lvm on

# Print partition table for verification
parted -s "${SYS_DISK}" print


# ############################################# #
# SECTION 3 - Partition Formatting

clear
mkfs.fat -F32 "${SYS_DISK}1"     # EFI partition
mkfs.ext4 -F "${SYS_DISK}2"      # /boot partition
mkswap "${SYS_DISK}3"            # swap partition

# sdb4 will be formatted later (see section X).

# ############################################# #
# SECTION 4 - Setting up an encrypted partition

# Encrypting the partition and setting the passphrase automatically
# --batch-mode avoids the "YES" confirmation prompt
echo -n "${LVM_PASSWD}" | cryptsetup luksFormat --batch-mode "${SYS_DISK}4" -
echo -n "${LVM_PASSWD}" | cryptsetup open --type luks "${SYS_DISK}4" lvm -

# ############################################# #
# SECTION 5 - Configuring LVM

# Create a physical volume
pvcreate /dev/mapper/lvm

# Create a volume group
vgcreate volgroup0 /dev/mapper/lvm

# Create the logical volumes
lvcreate -L 50GB volgroup0 -n lv_root   # root volume (50GB is more than enough to fill our system with programs)
lvcreate -l 100%FREE volgroup0 -n lv_home  # home vol. (rest of the disk)

# Insert a kernel module
modprobe dm_mod
vgscan
# read -p "Press Enter to continue..."
vgchange -ay

# Format the encrypted partitions
mkfs.ext4 /dev/volgroup0/lv_root
mkfs.ext4 /dev/volgroup0/lv_home



# ############################################# #
# SECTION 6 - Partition Mounting

# Mount root partition
mount /dev/volgroup0/lv_root /mnt

# Mount boot (2nd) partition
mount --mkdir "${SYS_DISK}2" /mnt/boot

# Mount home partition
mount --mkdir /dev/volgroup0/lv_home /mnt/home

# Turn on swap partition
swapon "${SYS_DISK}3"



# ############################################# #
# SECTION 7 - Installing the base system

clear
if ! pacstrap /mnt base --noconfirm --needed; then
    echo "ERROR: Failed to install base system. Exiting..."
    exit 1
fi

# ############################################# #
# SECTION 8 - Generate fstab file

clear
# Generate the file:
genfstab -U -p /mnt >> /mnt/etc/fstab



# ############################################# #
# SECTION 9 - Chroot into the installation

# Export common variables to a temporary file:
{
    echo "INSTALLATION_ROOT_PASSWD=${INSTALLATION_ROOT_PASSWD}"
    echo "USERNAME=${USERNAME}"
    echo "USER_PASSWD=${USER_PASSWD}"
    echo "SYS_DISK=${SYS_DISK}"
    echo "WIFI_SSID=${WIFI_SSID}"
    echo "WIFI_PASSWD=${WIFI_PASSWD}"
} >> /mnt/temp_vars.sh

cat /mnt/temp_vars.sh
echo "Exported common variables to a temporary file..."

# fetch the 2nd part of the script into the installation
echo "Downloading next part of setup script..."
curl -o /mnt/archInstall_2.sh https://raw.githubusercontent.com/FrancoSosaZ0206/MyArchInstallScript/main/archInstall_2.sh
chmod +x /mnt/archInstall_2.sh

# chroot into the installation and run part 2
echo "Entering chroot environment..."
arch-chroot /mnt /archInstall_2.sh || {
	echo "Error during chroot setup. Aborting unmount and reboot."
	exit 1
}

# After part 2:
umount -R /mnt
reboot

# Continues in part 3!
