#!/usr/bin/env bash

bootstrap() {

    # update system clock
    timedatectl set-ntp true

    # wipe disk
    sgdisk --zap-all /dev/${DISK} &> /dev/null
    wipefs -a /dev/${DISK} &> /dev/null

    # format disk
    parted /dev/${DISK} mklabel gpt &> /dev/null
    parted /dev/${DISK} mkpart primary fat32 1MiB 513MiB &> /dev/null
    parted /dev/${DISK} set 1 esp on &> /dev/null
    parted /dev/${DISK} mkpart primary ext4 513MiB 100% &> /dev/null

    # make luks
    echo -n "$PASSWORD" | cryptsetup -q luksFormat /dev/${DISK_PREFIX}2 -d -
    echo -n "$PASSWORD" | cryptsetup -q open /dev/${DISK_PREFIX}2 cryptlvm -d -

    # create lvm
    pvcreate /dev/mapper/cryptlvm
    vgcreate vg0 /dev/mapper/cryptlvm

    # create lvm partitions
    lvcreate -L ${SWAP_SIZE}G vg0 -n swap
    lvcreate -l 100%FREE vg0 -n root

    # format lvm partitions
    mkfs.fat -F32 /dev/${DISK_PREFIX}1
    mkfs.ext4 /dev/vg0/root
    mkswap /dev/vg0/swap

    # mount /root
    mount /dev/vg0/root /mnt

    # mount /boot
    mkdir /mnt/boot
    mount /dev/${DISK_PREFIX}1 /mnt/boot

    # mount swap
    swapon /dev/vg0/swap

    # install essential packages
    pacstrap /mnt base linux linux-firmware lvm2

    # generate /etc/fstab
    genfstab -U /mnt >> /mnt/etc/fstab

    #
    # need to chroot at this point
    #

    # add keyboard keymap encrypt lvm2 in HOOKS
    cp /mnt/etc/mkinitcpio.conf /mnt/etc/mkinitcpio.conf.bkp
    sed -i '/^HOOKS=.*/s/\<keyboard\> *//' /mnt/etc/mkinitcpio.conf
    sed -i '/^HOOKS=.*/s/\<keymap\> *//' /mnt/etc/mkinitcpio.conf
    sed -i '/^HOOKS=.*/s/\<encrypt\> *//' /mnt/etc/mkinitcpio.conf
    sed -i '/^HOOKS=.*/s/\<lvm2\> *//' /mnt/etc/mkinitcpio.conf
    sed -i 's/^HOOKS=.*\<block\>/& keyboard keymap encrypt lvm2/' /mnt/etc/mkinitcpio.conf

    # recreate initramfs
    arch-chroot /mnt mkinitcpio -P

    # install micro code
    if [ "${INSTALL_UCODE}" == "Yes" ]
        then
            arch-chroot /mnt pacman -Syu --noconfirm ${UCODE_PKG}
        fi

    # install grub
    arch-chroot /mnt pacman -Syu --noconfirm grub efibootmgr

    # configure grub
    cp /mnt/etc/default/grub /mnt/etc/default/grub.bkp
    export CRYPT_GRUB="cryptdevice=UUID=$(blkid /dev/${DISK_PREFIX}2 -s UUID -o value):cryptlvm root=/dev/vg0/root"
    sed -i 's@^GRUB_CMDLINE_LINUX="[^"]*@& '"${CRYPT_GRUB}"'@' /mnt/etc/default/grub

    if [ "${FAST_GRUB}" == "Yes" ]
        then
            sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /mnt/etc/default/grub
            sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=hidden/' /mnt/etc/default/grub
        fi

    # install grub to /boot
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id="Arch Linux"

    # generate grub config
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg


    # set timezone
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/${ZONE} /etc/localtime

    # generate /etc/adjtime
    arch-chroot /mnt hwclock --systohc


    # localization
    sed -i -e "s/#$LOCALE/$LOCALE/" /mnt/etc/locale.gen
    echo "LANG=${LOCALE}" > /mnt/etc/locale.conf

    echo "KEYMAP=${KEYBOARD}" > /mnt/etc/vconsole.conf

    arch-chroot /mnt locale-gen


    # hostname
    echo "${HOSTNAME}" > /mnt/etc/hostname

    # /etc/hosts
    LINE="127.0.0.1\tlocalhost"; grep -Pq "${LINE}" /mnt/etc/hosts || echo -e "${LINE}" >> /mnt/etc/hosts
    LINE="::1\t\tlocalhost"; grep -Pq "${LINE}" /mnt/etc/hosts || echo -e "${LINE}" >> /mnt/etc/hosts
    LINE="127.0.1.1\t${HOSTNAME}.localdomain\t${HOSTNAME}"; grep -Pq "${LINE}" /mnt/etc/hosts || echo -e "${LINE}" >> /mnt/etc/hosts

    # reflector 
    arch-chroot /mnt pacman -Syu --noconfirm reflector
    arch-chroot /mnt reflector --latest 50 --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    arch-chroot /mnt/ mkdir -p /etc/pacman.d/hooks
    cat > /mnt/etc/pacman.d/hooks/mirrorupgrade.hook << EOF
[Trigger]
Operation = Upgrade
Type = Package
Target = pacman-mirrorlist

[Action]
Description = Updating pacman-mirrorlist with reflector and removing pacnew...
When = PostTransaction
Depends = reflector
Exec = /bin/sh -c "reflector --latest 50 --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist; rm -f /etc/pacman.d/mirrorlist.pacnew"
EOF

    # install dhcpcd
    arch-chroot /mnt pacman -Syu --noconfirm dhcpcd
    arch-chroot /mnt systemctl enable dhcpcd

    # install wifi tools
    arch-chroot /mnt pacman -Syu --noconfirm dialog wpa_supplicant netctl

    # set root password
    echo -e "${PASSWORD}\n${PASSWORD}" | passwd --root /mnt


    # user / sudoers
    arch-chroot /mnt pacman -Syu --noconfirm sudo

    # enable sudo without passwd
    sed 's/# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/g' /mnt/etc/sudoers > /mnt/etc/sudoers.new
    cp /mnt/etc/sudoers.new /mnt/etc/sudoers
    rm /mnt/etc/sudoers.new

    # create user
    arch-chroot /mnt useradd -m -g users -G wheel -s /bin/bash ${USERNAME}
    echo "${USERNAME}:${PASSWORD}" | chpasswd --root /mnt


    # install yay
    if [ "${INSTALL_YAY}" == "Yes" ]
        then
            arch-chroot /mnt pacman -Syu --noconfirm git go binutils make gcc fakeroot
            arch-chroot /mnt su -c "git clone https://aur.archlinux.org/yay.git /home/${USERNAME}/yay" ${USERNAME}
            arch-chroot /mnt su -c "cd /home/${USERNAME}/yay && makepkg -si --noconfirm" ${USERNAME}
            arch-chroot /mnt su -c "rm -rf /home/${USERNAME}/yay" ${USERNAME}
        fi

}