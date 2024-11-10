#!/usr/bin/bash
# Fran's Arch Linux Automated Installation Script (part 2)

# ############################################# #
# Import variables from part 1

if [ -f /temp_vars.sh ]; then
    source /temp_vars.sh
else
    echo "Error: Variable file /temp_vars.sh not found!"
    exit 1
fi


# ############################################# #
# SECTION 10 - Setting up users

# Set installation's root password
echo "root:${INSTALLATION_ROOT_PASSWD}" | chpasswd

# Create a new user
useradd -m -g users -G wheel -s /bin/bash "${USERNAME}"

# Set user's password
# for simplicity's sake,
# it'll be the same as root for now.
echo "${USERNAME}:${USER_PASSWD}" | chpasswd

# Grant the newly created user super user (sudo) privileges
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers


# ############################################# #
# SECTION 11 - Configure & Speed Up Pacman
# This will save a TON of time when downloading
# all the packages.

# Enable colored output
sed -i 's/^Color/Color/' /etc/pacman.conf

# Enable parralel downloads
sed -i 's/^#ParallelDownloads/ParallelDownloads' /etc/pacman.conf

# Add ILoveCandy for some extra fun
echo "ILoveCandy" >> /etc/pacman.conf
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
          gparted htop man neofetch \
          firefox rhythmbox reaper easytag picard qjackctl \
          gimp krita obs-studio \
          nano vim libreoffice-fresh"

# Perform the installation (enjoy!)
pacman -S "${PACKAGES}" --noconfirm --needed


# left to install (via flathub and AUR):
# vs-code (visual-studio-code-bin) (using yay)
# extension manager (better than GNOME's extensions) (flatpak, better to just install it through GNOME Software)
# DaVinci Resolve


# ############################################# #
# SECTION 13 - Generating RAM Disk(s) for our Kernel(s)

# Edit mkcpio config file for our encryption to work
sed -i 's/^HOOKS=(base /HOOKS=(base encrypt lvm2 /' /etc/mkinitcpio.conf


# Generate initramfs for each of the previously installed kernels:
mkinitcpio -p linux
mkinitcpio -p linux-lts



# ############################################# #
# SECTION 14 - Post-Installation (misc.) Setup

# Set locales
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
sed -i 's/^#es_AR.UTF-8/es_AR.UTF-8/' /etc/locale.gen

# Generate locales
locale-gen

# Add our encrypted volume to the GRUB config file
sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3/& cryptdevice=${DISK}4:volgroup0/" /etc/default/grub

# Enabling os-prober to detect multi-os systems in GRUB:
sed -i "s/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false" /etc/default/grub

# Mount EFI partition (the 1st we created)
mount --mkdir "${DISK}1" /boot/EFI

# Install GRUB
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck

# Copy grub locale file into our directory
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo

# Make grub config
grub-mkconfig -o /boot/grub/grub.cfg

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


# Clean the screen
clear
# Print checkout message
echo -e "\nInstallation complete! Run:\n\numount -a\nreboot\n\nEnjoy your new Arch Linux System! :)"

# Exit the installation, stopping this script
exit
