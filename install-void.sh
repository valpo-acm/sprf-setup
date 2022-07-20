#!/bin/sh

# Assumes Void is glibc
# Assumes a DISK w/ 3 partitions
# Assumes BIOS booting

# EX:
# /dev/sdb
#  |- /dev/sdb1 (/boot)
#  |- /dev/sdb2 (swap)
#  \- /dev/sdb3 (/)

# TODO: LVM

DISK="${DISK:-/dev/sdb}"
HOST="${HOST:-labpc}"
ROOTPASS="${ROOTPASS:-changeme}"
# Void's glibc repo
REPO=https://repo-default.voidlinux.org/current
# Arch of the computer we are installing onto
ARCH=x86_64

err() {
    echo $@
    exit 1
}

xi() {
    yes | XBPS_ARCH=$ARCH xbps-install -S -r /mnt -R "$REPO" "$@"
}

check_env() {
    [ "root" = $(whoami) ] || err "You need to be root to run this script"
    [ -e /var/db/xbps/keys ] || err "Install media needs to be Void linux"
    command -v curl || err "You need access to curl to run this script"
    command -v xbps-install || err "You need access to xbps-install to run this script"
    command -v xbps-reconfigure || err "You need access to xbps-reconfigure to run this script"
}

format_partitions() {
    mkfs.ext4 -F "${DISK}1"
    mkswap -f "${DISK}2"
    mkfs.ext4 -F "${DISK}3"
}

mount_partitions() {
    mount "${DISK}3" "/mnt"
    mkdir -p "/mnt/boot/"
    mount "${DISK}1" "/mnt/boot"
    swapon "${DISK}2"
}

install_void() {
    mkdir -p /mnt/var/db/xbps/keys
    cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys
    xi base-system
}

install_packages() {
    # TODO: mpich, nis (ldap & kerberos are available), scala

    # Make sure to install the non-free repo so that we have access to nvida stuff.
    xi void-repo-nonfree
    pkgs="
openssh
base-devel
net-tools
docker
mesa
python3
python3-pip
libopencv
libopencv-devel
openmpi
openmpi-devel
lm_sensors
libfreeglut
libfreeglut-devel
libXi
libXmu
binutils
libnfs
nfs-utils
sv-netmount
openldap
openldap-tools
atop
htop

gparted
gnome-disk-utility
wireshark
xterm
lxappearance
firefox
chromium

vscode
emacs-gtk3
neovim
vim
nano
eclipse

xorg
radeontop
mesa-vaapi
mesa-vdpau
WindowMaker
9wm
gnome
cinnamon
kde5
kde5-baseapps
lxdm
dbus

octave
maxima
sagemath

gdb
tcc
clang
openjdk
openjdk17
ghc
clojure
sbcl
ccl
go
rust
gprolog
ruby
julia
gcc-fortran
R

"
    xi $(echo $pkgs | tr '\n' ' ')
}

configure_void() {
    echo "$HOST" >/mnt/etc/hostname
    # Glibc specific - set locale
    echo "en_US.UTF-8 UTF-8" >/mnt/etc/locale.gen
    xbps-reconfigure -r /mnt -f glibc-locales
    # Generate the filesystem table using a really nice script.
    [ -e genfstab ] || {
        curl -LO https://raw.githubusercontent.com/cemkeylan/genfstab/master/genfstab
        chmod +x genfstab
    }
    ./genfstab -U /mnt >>/mnt/etc/fstab
}

install_bootloader() {
    xi grub
}

finalize() {
    # Download kiss-chroot, since it makes this whole ordeal less painful.
    [ -e kiss-chroot ] || {
        curl -LO https://raw.githubusercontent.com/kiss-community/kiss/master/contrib/kiss-chroot
        chmod +x kiss-chroot
    }
    cat <<EOF >/mnt/finishup.sh
#!/bin/sh
yes "$ROOTPASS" | passwd
chsh -s /bin/bash root
grub-install "$DISK"
grub-mkconfig -o /boot/grub/grub.cfg
xbps-reconfigure -fa
EOF
    chmod +x /mnt/finishup.sh
    cat <<EOF >/mnt/afterreboot.sh
#!/bin/sh
for s in dhcpcd dbus lxdm; do
    ln -s /etc/sv/\$s /var/service
done
EOF
    chmod +x /mnt/afterreboot.sh
    ./kiss-chroot /mnt
}

main() {
    check_env
    format_partitions
    mount_partitions
    install_void
    install_packages
    configure_void
    install_bootloader
    finalize
}

main
