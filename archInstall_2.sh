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
# Enable:
#   colored output,
#   parallel downloads, and
#   Add ILoveCandy for some extra fun
#       Super important, of course.
#       Mhm.
#       Totally needed.
sed -i \
    -e "s/^#Color/Color/" \
    -e "s/^#ParallelDownloads/ParallelDownloads/" \
    -e "/^#DisableSandbox/a ILoveCandy" \
    /etc/pacman.conf

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
man ntfs-3g \
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
# Edit mkcpio config file:

#   for our encryption to work, and
#   to add hibernation support to our system (and save power)
sed -i "/^HOOKS=/{ \
    s/block/& encrypt lvm2/; \
    s/filesystems/& resume/ \
}" /etc/mkinitcpio.conf
#   enable initramfs image compression (for better hibernation)
sed -i "s/^#COMPRESSION=\"zstd\"/COMPRESSION=\"zstd\"/" /etc/mkinitcpio.conf

# Generate initramfs for each of the previously installed kernels:
mkinitcpio -p linux
mkinitcpio -p linux-lts



# ############################################# #
# SECTION 14 - Post-Installation (misc.) Setup

clear
# Set locales
sed -i \
    -e "s/^#en_US.UTF-8/en_US.UTF-8/" \
    -e "s/^#es_AR.UTF-8/es_AR.UTF-8/" \
    /etc/locale.gen

# Generate locales
locale-gen

# Add custom settings to the locale config file
cat << EOF > /etc/locale.conf
LANG=en_US.UTF-8
LC_NUMERIC=es_AR.UTF-8
LC_TIME=es_AR.UTF-8
LC_MONETARY=es_AR.UTF-8
LC_PAPER=es_AR.UTF-8
LC_MEASUREMENT=es_AR.UTF-8
EOF

# Add our encrypted volume to the GRUB config file
sed -i "s,GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3,& cryptdevice=${SYS_DISK}4:volgroup0," /etc/default/grub

# Define the expected line for verification
EXPECTED="GRUB_CMDLINE_LINUX_DEFAULT=\"loglevel=3 cryptdevice=${SYS_DISK}4:volgroup0 quiet\""

# Verify that the line matches exactly as expected
if ! grep -q "^${EXPECTED}$" /etc/default/grub; then
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

# Install GRUB
if ! grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=Arch_btw --recheck; then
    echo "ERROR: GRUB installation failed!"
    exit 1
fi

# Copy grub locale file into our directory
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo

# Make grub config
if ! grub-mkconfig -o /boot/grub/grub.cfg; then
    echo "ERROR: Failed to generate GRUB configuration!"
    exit 1
fi


# ······································ #
# SUDOERS CONFIGURATION:
# ······································ #

# Grant the newly created user sudo privileges
echo '%wheel ALL=(ALL) ALL' | EDITOR='tee -a' visudo

if grep '# %wheel ALL=(ALL) ALL' /etc/sudoers; then
    echo "ERROR: couldn't grant sudo privileges to $USERNAME."
    read -p "Press enter to continue..."
fi

# (Easter Egg) Enable insults
echo 'Defaults insults' | EDITOR='tee -a' visudo

# Temporarily grant passwordless sudo privileges to the user
# (removed once the third script is done executing)
echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" | EDITOR='tee -a' visudo


# Enable GNOME greeter
systemctl enable gdm

# Enable wifi
systemctl enable NetworkManager

# Enable bluetooth, turn it on and off
modprobe btusb
systemctl enable bluetooth
rfkill toggle bluetooth & sleep 2
rfkill toggle bluetooth

# Install rest of the packages
PACKAGES="firefox \
rhythmbox audacious \
reaper easytag qjackctl \
gimp krita inkscape \
vim libreoffice-fresh \
yt-dlp \
android-tools cyme \
fish kitty \
gparted htop fastfetch dconf-editor wget"
if ! pacman -Syu ${PACKAGES} --noconfirm --needed; then
    clear
    echo "Error installing packages. Exiting..."
    exit 1
fi

# Install remaining packages
PACKAGES="com.mattjakeman.ExtensionManager \
com.discordapp.Discord \
org.gtk.Gtk3theme.Adwaita-dark \
org.musicbrainz.Picard \
com.obsproject.Studio \
com.obsproject.Studio.Plugin.DroidCam \
org.gnome.Solanum"
flatpak install flathub $PACKAGES -y



clear
echo "Downloading the third part of the setup script..."

SCRIPT_DIR="/home/${USERNAME}/archInstall_3.sh"

# fetch the 3rd part of the script into the installation
curl -o "${SCRIPT_DIR}" https://raw.githubusercontent.com/FrancoSosaZ0206/MyArchInstallScript/main/archInstall_3.sh
# make the script executable
chmod +x "${SCRIPT_DIR}"
# grant execution permissions to the user
chown ${USERNAME}:${USERNAME} "${SCRIPT_DIR}"

# Move temp_vars.sh to the user's home directory
mv /temp_vars.sh "/home/${USERNAME}/"

# Edit user's .bashrc to execute the third script when opening terminal
echo "if [ -f ~/archInstall_3.sh ]; then
    ~/archInstall_3.sh
fi

# ···························· #
# ${USERNAME}'s custom commands:

fastfetch

# ···························· #
" >> "/home/${USERNAME}/.bashrc"


# Print checkout message
clear
cat << EOF 
---------------------------------------

Installation complete!
The system will now reboot. After that,
Open the console program to perform
the post-installation sript.

Enjoy your new Arch Linux System! :)

---------------------------------------

EOF
sleep 10

# Cleanup - Delete this script
rm -- "$0"
# Exit the installation, stopping this script
exit 0
