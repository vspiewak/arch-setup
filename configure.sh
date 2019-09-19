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

# virtualbox
IS_VIRTUALBOX=$(dmesg --notime | grep -i "virtualbox" | wc -l)
if [ "$IS_VIRTUALBOX" -gt "0" ]; then
  pacman -Syu --noconfirm virtualbox-guest-utils xf86-video-vmware
fi

# xorg
pacman -Syu --noconfirm xorg xorg-server

# gnome
pacman -Syu --noconfirm gnome
pacman -Syu gnome-tweaks-tool

mkdir -p /etc/dconf/profile/
cat > /etc/dconf/profile/user <<'EOF'
user-db:user
system-db:local
EOF

mkdir -p /etc/dconf/db/local.d/
cat > /etc/dconf/db/local.d/10_gnome <<'EOF'
[org/gnome/desktop/wm/preferences]
button-layout='appmenu:minimize,maximize,close'
EOF

exit 0

# windows button on gnome for a better experience
sudo -u vince -H dbus-launch --exit-with-session gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,maximize,close

# gdm
pacman -Syu --noconfirm gdm
#systemctl enable gdm.service

# font emoji
#pacman -Syu ----noconfirm noto-fonts-emoji
pacman -Syu --noconfirm ttf-joypixels

# yay
pacman -Syu --needed --noconfirm base-devel

pacman -Syu --noconfirm git

pacman -Syu --noconfirm go

su -c "rm -rf /tmp/yay && git clone https://aur.archlinux.org/yay.git /tmp/yay" vince
su -c "cd /tmp/yay && makepkg -si --noconfirm" vince

# install dash to dock
su -c "yay -Syu --noconfirm gnome-shell-extension-dash-to-dock" vince

su - -c "gnome-shell-extension-tool -e dash-to-dock" vince
su - -c "gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true" vince
su - -c "gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM" vince
su - -c "gsettings set org.gnome.shell.extensions.dash-to-dock extend-height true" vince
su - -c "gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true" vince
su - -c "gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32" vince
