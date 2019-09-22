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
pacman -Syu  --noconfirm gnome-tweaks

# gdm
pacman -Syu --noconfirm gdm
systemctl enable gdm.service

# font emoji
#pacman -Syu ----noconfirm noto-fonts-emoji
pacman -Syu --noconfirm ttf-joypixels


# yay
pacman -Syu --needed --noconfirm base-devel
pacman -Syu --noconfirm git
pacman -Syu --noconfirm go

su -c "rm -rf /tmp/yay && git clone https://aur.archlinux.org/yay.git /tmp/yay" vince
su -c "cd /tmp/yay && makepkg -si --noconfirm" vince


# gnome shell: dash to dock
su -c "yay -Syu --noconfirm gnome-shell-extension-dash-to-dock" vince

# gnome shell: arch-update
su -c "yay -Syu --noconfirm gnome-shell-extension-arch-update" vince


# install gnome defaults settings
mkdir -p /etc/dconf/profile
cat > /etc/dconf/profile/user <<'EOF'
user-db:user
system-db:local
EOF

mkdir -p /etc/dconf/db/local.d
cat > /etc/dconf/db/local.d/00_defaults <<'EOF'
[org/gnome/shell]
enabled-extensions=['dash-to-dock@micxgx.gmail.com', 'drive-menu@gnome-shell-extensions.gcampax.github.com', 'arch-update@RaphaelRochet']
favorite-apps=['org.gnome.Nautilus.desktop','org.gnome.Terminal.desktop','org.gnome.Epiphany.desktop']

[org/gnome/shell/extensions/dash-to-dock]
show-apps-at-top=true
dock-position='BOTTOM'
extend-height=true
dock-fixed=true
dash-max-icon-size=32

[org/gnome/desktop/interface]
gtk-theme='Adwaita-dark'

[org/gnome/desktop/wm/preferences]
button-layout='appmenu:minimize,maximize,close'
num-workspaces=5
EOF

# update gnome settings
dconf update

pacman -Syu --noconfirm jq

pacman -Syu --noconfirm jdk-openjdk jdk8-openjdk

pacman -Syu --noconfirm atom

#pacman -Syu --noconfirm chromium
su -c "yay -Syu --noconfirm google-chrome" vince

pacman -Syu --noconfirm firefox-developer-edition

pacman -Syu --noconfirm telegram-desktop

pacman -Syu --noconfirm vlc

su -c "yay -Syu --noconfirm slack-desktop" vince

su -c "yay -Syu --noconfirm intellij-idea-ultimate-edition" vince

pacman -Syu --noconfirm docker
