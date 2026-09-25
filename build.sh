#!/bin/bash
# SAS OS - Lightweight Debian-based Linux distribution
# Automated installer ISO build script
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "Run as root: sudo $0"
    exit 1
fi

WORK_DIR="${HOME}/SAS-build"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Cleaning previous build..."
if [[ -d "${WORK_DIR}" ]]; then
    cd "${WORK_DIR}"
    lb clean --purge 2>/dev/null || true
    cd "${HOME}"
    rm -rf "${WORK_DIR}"
fi

mkdir -p "${WORK_DIR}"
cd "${WORK_DIR}"

echo "==> Installing build dependencies..."
apt-get update -qq
for pkg in \
    live-build debootstrap squashfs-tools xorriso isolinux \
    syslinux-efi grub-pc-bin grub-efi-amd64-bin \
    imagemagick wget ca-certificates; do
    dpkg -l | grep -q "^ii  ${pkg} " || \
        apt-get install -y -qq --no-install-recommends "${pkg}"
done

echo "==> Configuring Debian Bookworm live-build..."
lb config noauto \
    --distribution bookworm \
    --architectures amd64 \
    --archive-areas "main contrib non-free non-free-firmware" \
    --mode debian \
    --debian-installer true \
    --debian-installer-gui true \
    --debian-installer-distribution bookworm \
    --mirror-bootstrap http://deb.debian.org/debian/ \
    --mirror-chroot http://deb.debian.org/debian/ \
    --mirror-binary http://deb.debian.org/debian/ \
    --mirror-debian-installer http://deb.debian.org/debian/ \
    --apt-indices false \
    --apt-recommends true \
    --binary-images iso-hybrid \
    --bootloaders "syslinux,grub-efi" \
    --iso-application "SAS OS" \
    --iso-publisher "SAS" \
    --iso-volume "SAS_INSTALLER" \
    --memtest none \
    --win32-loader false

mkdir -p config/package-lists config/includes.installer \
    config/hooks/normal config/bootloaders/isolinux \
    config/bootloaders/grub-pc

cat > config/package-lists/system.list.chroot <<'EOF'
task-lxde-desktop
lxde
lxappearance
lxde-common
lxpanel
lxsession
openbox
obconf
pcmanfm
lxterminal
lightdm
lightdm-gtk-greeter
lightdm-gtk-greeter-settings
xorg
xserver-xorg-video-all
xserver-xorg-input-all
plymouth
plymouth-themes
desktop-base
systemd-sysv
dbus
udev
network-manager
network-manager-gnome
wireless-tools
wpasupplicant
firmware-linux
firmware-linux-free
firmware-linux-nonfree
firmware-misc-nonfree
firmware-iwlwifi
firmware-realtek
bluez
bluez-tools
pulseaudio
pavucontrol
alsa-utils
sudo
locales
ca-certificates
wget
imagemagick
sqlite3
libsqlite3-dev
EOF

cat > config/package-lists/desktop.list.chroot <<'EOF'
firefox-esr
chromium
gedit
pluma
file-roller
gparted
gnome-disk-utility
baobab
galculator
gpicview
xarchiver
nitrogen
feh
lxappearance
gtk2-engines
gtk2-engines-murrine
gtk2-engines-pixbuf
arc-theme
papirus-icon-theme
numix-gtk-theme
breeze-cursor-theme
fonts-dejavu
fonts-liberation
fonts-noto
fonts-roboto
fonts-ubuntu
libreoffice-writer
libreoffice-calc
libreoffice-impress
vlc
gimp
inkscape
audacity
transmission-gtk
synaptic
menulibre
screenfetch
neofetch
EOF

cat > config/package-lists/dev.list.chroot <<'EOF'
git
build-essential
gcc
g++
make
cmake
automake
autoconf
pkg-config
python3
python3-pip
python3-venv
python3-dev
python3-mysql.connector
nodejs
npm
default-jdk
default-jre
golang-go
rustc
cargo
vim
vim-gtk3
nano
geany
geany-plugins
htop
btop
tree
curl
wget
net-tools
openssh-server
openssh-client
rsync
unzip
zip
p7zip-full
gdb
valgrind
strace
EOF

cat > config/includes.installer/preseed.cfg <<'EOF'
d-i debian-installer/locale string en_US.UTF-8
d-i localechooser/supported-locales multiselect en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us

d-i netcfg/choose_interface select auto
d-i netcfg/get_hostname string sasos
d-i netcfg/get_domain string local

d-i mirror/country string manual
d-i mirror/http/hostname string deb.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

# User and password remain interactive.
d-i passwd/root-login boolean false
d-i passwd/user-default-groups string audio cdrom video sudo netdev plugdev

d-i clock-setup/utc boolean true
d-i time/zone string US/Eastern
d-i clock-setup/ntp boolean true

d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

tasksel tasksel/first multiselect standard
d-i pkgsel/include string task-lxde-desktop openssh-server build-essential git
d-i pkgsel/upgrade select full-upgrade
popularity-contest popularity-contest/participate boolean false

d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i grub-installer/bootdev string default

d-i finish-install/reboot_in_progress note
EOF

cat > config/hooks/normal/0050-download-wallpaper.hook.chroot <<'EOF'
#!/bin/bash
set -euo pipefail

mkdir -p /usr/share/backgrounds/sasos
cd /usr/share/backgrounds/sasos

wget -q -O default.jpg \
  "https://images.unsplash.com/photo-1557683316-973673baf926?w=1920&h=1080&fit=crop" || true

if [[ ! -s default.jpg ]]; then
    convert -size 1920x1080 \
        gradient:'#0f2027-#2c5364' \
        -gravity center \
        -pointsize 80 \
        -fill white \
        -font DejaVu-Sans-Bold \
        -annotate +0-50 'SAS OS' \
        -pointsize 30 \
        -annotate +0+50 'Development Environment' \
        default.jpg
fi

wget -q -O space.jpg \
  "https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=1920&h=1080&fit=crop" || true
wget -q -O mountain.jpg \
  "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1920&h=1080&fit=crop" || true
wget -q -O nature.jpg \
  "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1920&h=1080&fit=crop" || true

chmod 644 /usr/share/backgrounds/sasos/*.jpg
EOF
chmod +x config/hooks/normal/0050-download-wallpaper.hook.chroot

cat > config/hooks/normal/0100-customize.hook.chroot <<'EOF'
#!/bin/bash
set -euo pipefail

echo "SAS" > /etc/hostname
grep -q '127.0.1.1 SAS' /etc/hosts || echo '127.0.1.1 SAS' >> /etc/hosts

mkdir -p /etc/skel/.config/lxpanel/LXDE/panels
cat > /etc/skel/.config/lxpanel/LXDE/panels/panel <<'LXPANEL'
Global {
    edge=bottom
    widthtype=percent
    width=100
    height=32
    transparent=0
    tintcolor=#000000
    alpha=230
    autohide=0
    iconsize=24
    fontsize=10
    fontcolor=#ffffff
}

Plugin {
    type=menu
    Config {
        image=/usr/share/pixmaps/debian-logo.png
        system {}
        separator {}
        item { command=run }
        separator {}
        item {
            image=gnome-logout
            command=logout
        }
    }
}

Plugin {
    type=launchbar
    Config {
        Button { id=firefox-esr.desktop }
        Button { id=lxterminal.desktop }
        Button { id=pcmanfm.desktop }
        Button { id=gedit.desktop }
    }
}

Plugin { type=space Config { Size=4 } }
Plugin { type=pager }
Plugin { type=space Config { Size=4 } }
Plugin { type=taskbar expand=1 Config {
    tooltips=1
    IconsOnly=0
    ShowAllDesks=0
    UseMouseWheel=1
    UseUrgencyHint=1
    FlatButton=0
    MaxTaskWidth=200
    spacing=1
    GroupedTasks=0
}}
Plugin { type=cpu }
Plugin { type=tray }
Plugin { type=volumealsa }
Plugin { type=netstat }
Plugin { type=dclock Config {
    ClockFmt=%I:%M %p
    TooltipFmt=%A %x
    BoldFont=1
    IconOnly=0
}}
LXPANEL

mkdir -p /etc/skel/.config/pcmanfm/LXDE
cat > /etc/skel/.config/pcmanfm/LXDE/desktop-items-0.conf <<'PCMANFM'
[*]
wallpaper_mode=stretch
wallpaper_common=1
wallpaper=/usr/share/backgrounds/sasos/default.jpg
desktop_bg=#1a1a1a
desktop_fg=#ffffff
desktop_shadow=#000000
show_wm_menu=1
show_documents=0
show_trash=1
show_mounts=1
PCMANFM

mkdir -p /etc/skel/.config/gtk-3.0
cat > /etc/skel/.config/gtk-3.0/settings.ini <<'GTK3'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Ubuntu 10
gtk-cursor-theme-name=Breeze_Snow
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-xft-rgba=rgb
GTK3

mkdir -p /etc/skel/.config/openbox
cat > /etc/skel/.config/openbox/lxde-rc.xml <<'OPENBOX'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <theme>
    <name>Arc-Dark</name>
    <titleLayout>NLIMC</titleLayout>
    <keepBorder>yes</keepBorder>
    <animateIconify>yes</animateIconify>
  </theme>
  <desktops>
    <number>4</number>
    <firstdesk>1</firstdesk>
    <names>
      <name>Desktop 1</name>
      <name>Desktop 2</name>
      <name>Desktop 3</name>
      <name>Desktop 4</name>
    </names>
  </desktops>
</openbox_config>
OPENBOX

mkdir -p /etc/skel/.config/lxsession/LXDE
cat > /etc/skel/.config/lxsession/LXDE/desktop.conf <<'LXSESSION'
[GTK]
sNet/ThemeName=Arc-Dark
sNet/IconThemeName=Papirus-Dark
sGtk/FontName=Ubuntu 10
sGtk/CursorThemeName=Breeze_Snow
iGtk/ToolbarStyle=3
iGtk/ButtonImages=1
iGtk/MenuImages=1
iGtk/CursorThemeSize=24
iXft/Antialias=1
iXft/Hinting=1
sXft/HintStyle=hintfull
sXft/RGBA=rgb

[Core]
Wallpaper=/usr/share/backgrounds/sasos/default.jpg
LXSESSION

mkdir -p /etc/skel/Desktop

cat > /etc/skel/Desktop/Terminal.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Terminal
Comment=Use the command line
Icon=utilities-terminal
Exec=lxterminal
Categories=System;TerminalEmulator;
DESKTOP

cat > /etc/skel/Desktop/Firefox.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Firefox
Comment=Web Browser
Icon=firefox-esr
Exec=firefox-esr
Categories=Network;WebBrowser;
DESKTOP

cat > /etc/skel/Desktop/Files.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Files
Comment=File Manager
Icon=system-file-manager
Exec=pcmanfm
Categories=System;FileManager;
DESKTOP

cat > /etc/skel/Desktop/Wallpaper.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Change Wallpaper
Comment=Select desktop wallpaper
Icon=preferences-desktop-wallpaper
Exec=nitrogen /usr/share/backgrounds/sasos
Categories=Settings;DesktopSettings;
DESKTOP

chmod +x /etc/skel/Desktop/*.desktop

cat > /etc/skel/Desktop/Welcome.txt <<'WELCOME'
Welcome to SAS OS!
==================

A lightweight Debian-based development environment.

Desktop:
- LXDE
- Openbox
- Arc-Dark theme
- Papirus icons

Development:
- Python 3
- Node.js
- Java
- Go
- Rust
- GCC/G++
- CMake
- Git
- GDB
- Valgrind

Applications:
- Firefox ESR
- Chromium
- LibreOffice
- GIMP
- Inkscape
- VLC
- Audacity

Use the desktop shortcuts and application menu to get started.
WELCOME

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8

cat > /etc/sysctl.d/99-performance.conf <<'SYSCTL'
vm.swappiness=10
vm.dirty_ratio=15
vm.dirty_background_ratio=10
vm.vfs_cache_pressure=50
SYSCTL

apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
EOF
chmod +x config/hooks/normal/0100-customize.hook.chroot

cat > config/bootloaders/isolinux/isolinux.cfg <<'EOF'
default install
timeout 30
prompt 1

say ==========================================
say          SAS OS Installer
say ==========================================
say
say   Press ENTER to install SAS OS
say   Starting installation in 3 seconds...
say

label install
    kernel /install/gtk/vmlinuz
    append initrd=/install/gtk/initrd.gz priority=critical

label installtext
    kernel /install/vmlinuz
    append initrd=/install/initrd.gz priority=critical
EOF

cat > config/bootloaders/grub-pc/grub.cfg <<'EOF'
set default=0
set timeout=3
set menu_color_normal=white/black
set menu_color_highlight=black/white

menuentry "Install SAS OS" {
    linux /install/vmlinuz priority=critical
    initrd /install/initrd.gz
}

menuentry "Install SAS OS (Graphical)" {
    linux /install/gtk/vmlinuz priority=critical
    initrd /install/gtk/initrd.gz
}

menuentry "Install SAS OS (Text Mode)" {
    linux /install/vmlinuz priority=critical
    initrd /install/initrd.gz
}
EOF

echo "==> Building ISO..."
if ! lb build 2>&1 | tee build.log; then
    echo "Build failed. Check ${WORK_DIR}/build.log"
    exit 1
fi

ISO_FILE="$(find . -maxdepth 1 -type f -name '*.iso' -printf '%f\n' | head -n1)"

if [[ -n "${ISO_FILE}" ]]; then
    mv "${ISO_FILE}" SAS.iso
    echo
    echo "=========================================="
    echo "SAS OS ISO created successfully:"
    echo "${WORK_DIR}/SAS.iso"
    echo "=========================================="
else
    echo "Build failed: ISO not created"
    exit 1
fi
