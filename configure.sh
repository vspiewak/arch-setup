#!/usr/bin/env bash
HOSTNAME="t490s"
TIMEZONE="Europe/Paris"

username=vince
password=test

# timezone
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc


# localization
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
echo 'LANG=en_US.UTF-8' >> /etc/locale.conf
locale-gen


# hostname & /etc/hosts
echo "${HOSTNAME}" > /etc/hostname
#echo "127.0.0.1   localhost" >> /etc/hosts
#echo "::1         localhost" >> /etc/hosts
#echo "127.0.1.1   ${HOSTNAME}.localdomain   ${HOSTNAME}" >> /etc/hosts


# user / sudoers
pacman -Syu --noconfirm sudo

# enable sudo without passwd
sed 's/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers > /etc/sudoers.new
cp /etc/sudoers.new /etc/sudoers
rm /etc/sudoers.new

# create user
useradd -m -g users -G wheel -s /bin/bash ${username}
echo "${username}:${password}" | chpasswd
#echo "root:${password}" | chpasswd


# xorg
pacman -Syu --noconfirm xorg xorg-server

# gnome
pacman -Syu --noconfirm gnome

# windows button on gnome for a better experience
gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,maximize,close

# gdm
pacman -Syu --noconfirm gdm
#systemctl enable gdm.service

# font emoji
#pacman -Syu ----noconfirm noto-fonts-emoji
pacman -Syu ----noconfirm ttf-joypixels

# yay
pacman -Syu --needed --noconfirm base-devel

pacman -Syu --noconfirm git

pacman -Syu --noconfirm go

su -c "rm -rf /tmp/yay && git clone https://aur.archlinux.org/yay.git /tmp/yay" vince
su -c "cd /tmp/yay && makepkg -si --noconfirm" vince

# install dash to dock
yay -Syu --noconfirm gnome-shell-extension-dash-to-dock
