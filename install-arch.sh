#!/bin/sh

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
# A comma separated list of users, with their uid number separed by a colon.
# EX: USERS="nrosasco:1000,mpiuser:5959"
USERS="${USERS:-'nrosasco:1000'}"

err() {
    echo $@
    exit 1
}

pi() {
    pacman --sysroot /mnt --noconfirm -Su "$@"
}

check_env() {
    [ "root" = $(whoami) ] || err "You need to be root to run this script"
    command -v curl || err "You need access to curl to run this script"
    command -v pacstrap || err "You need access to pacstrap to run this script"
    command -v pacman || err "You need access to pacman to run this script"
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

install_arch() {
    pacstrap /mnt base base-devel linux linux-firmware
}

install_packages() {
    # TODO: mpich, nis (ldap & kerberos are available), scala

    # Make sure to install the non-free repo so that we have access to nvida stuff.
    pkgs="$(cat server/arch-packages)"
    pi $(echo $pkgs | tr '\n' ' ')
}

configure_arch() {
    echo "$HOST" >/mnt/etc/hostname
    # Glibc specific - set locale
    echo "en_US.UTF-8 UTF-8" >/mnt/etc/locale.gen
    # Generate the filesystem table using a really nice script.
    [ -e genfstab ] || {
        curl -LO https://raw.githubusercontent.com/cemkeylan/genfstab/master/genfstab
        chmod +x genfstab
    }
    ./genfstab -U /mnt >>/mnt/etc/fstab
}

install_bootloader() {
    pi grub efibootmgr
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
for up in $(echo $USERS | tr ',' ' '); do
    name=\$(echo \$up | cut -d':' -f1)
    inum=\$(echo \$up | cut -d':' -f2)
    useradd -m -u \$inum \$name
    chsh -s /bin/bash \$name
    yes "$ROOTPASS" | passwd \$name
done
grub-install --target=i386-pc "$DISK"
grub-mkconfig -o /boot/grub/grub.cfg
EOF
    chmod +x /mnt/finishup.sh
    cat <<EOF >/mnt/afterreboot.sh
#!/bin/sh
for s in dhcpcd dbus lxdm sshd; do
    systemctl enable \$s
done
EOF
    chmod +x /mnt/afterreboot.sh
    echo "sh /finishup.sh"  | ./kiss-chroot /mnt
}

main() {
    check_env
    format_partitions
    mount_partitions
    install_arch
    install_packages
    configure_arch
    install_bootloader
    finalize
}

main
