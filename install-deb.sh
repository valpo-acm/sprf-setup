#!/bin/sh

# Author       : Spencer Gannon
# Description  : Does all of the tedious installs for Valparaiso
#                University's CIS Department Ubuntu/Linux machines
# Instructions : Run using sudo (?) or as root user

install_pkgs() {
    echo "Do you want to install all packages? [y/n]: "
    read ANSWER

    case "$ANSWER" in
    [yY])
        echo "Installing packages..."
        pkgs="
git
pdsh
htop
atop
neofetch
screen
ssh
openssh-client
default-jdk
gcc
tcc
g++
clang
python
net-tools
nm-connection-editor
gdb
gksudo
docker
mesa-utils
python-nose
python3-pip
lobopencv-dev
python3-opencv
openmpi-common
mpich
libopenmpi-dev
openmpi-doc
nis
yp-tools
lm-sensors
freeglut3
freeglut3-dev
libxi-dev
libxmu-dev
nvidia-cuda-dev
nvidia-cuda-toolkit
build-essential
binutils
lightdm-gtk-greeter-settings
lightdm-settings
nfs-kernel-server
nfs-common
emacs
neovim"
        for pkg in $pkgs; do
            apt-get install -y $pkg
        done
        ;;
    *)
        echo "Package install skipped..."
        ;;
    esac
}

install_pkgs

#the Nvidia driver stuff; requires diskBox and sharedFiles to be mounted
echo "Do you have sharedFiles mounted? [y/n]: "
read ANSWER
case "$ANSWER" in
[yY])
    echo "Do you want to install Maple? [y/n]: "
    read ANSWER

    case "$ANSWER" in
    [yY])
        /mnt/sharedFiles/systems/installs/Maple2019.0LinuxX64Installer.run
        ;;
    *) echo 'no' ;;
    esac

    echo "Do you want to install nvpersistence? [y/n]: "
    read ANSWER

    case "$ANSWER" in
    [yY])
        cd /mnt/sharedFiles/systems/dane/nvcheck/
        ./nvcheck_update
        cd $OLDPWD
        cd nvpersistence/
        cp nvpersistence.service /etc/systemd/system/
        cp nvenablepm /etc/
        systemctl start nvpersistence.service
        systemctl enable nvpersistence.service
        ;;
    *) echo 'no' ;;
    esac
    ;;
*) ;;
esac
