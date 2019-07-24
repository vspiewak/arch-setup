#!/usr/bin/env bash
DEVICE=/dev/sda
EFI_DIR=/sys/firmware/efi


exec 3<>/dev/tty

echo # new line
echo "This will wipe your drives !"

while [[ ! $REPLY =~ ^[YyNn]$ ]]; do
  read -u 3 -p "Are you sure? [y/N] " -n 1 -r
  REPLY=${REPLY:-N}
  echo
done

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo -e "Cancel."
  exit 0
else
  echo
fi


# check boot mode
if test -f "${EFI_DIR}"; then
  echo "Boot Mode: UEFI"
else
  echo "Boot Mode: BIOS"
fi


# enable ntp
timedatectl set-ntp true


# swapoff & umount all
swapoff -a
for n in ${DEVICE}*; do umount -f $n; done


# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "defualt" will send a empty
# line terminated with a newline to take the fdisk default.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${DEVICE}
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
  +2G # 2G swap parttion
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  a # make a partition bootable
  2 #
  t # change partition type to swap
  1 # swap partition
  82 # type swap
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF


# swap partition
mkswap ${DEVICE}1
swapon ${DEVICE}1


# root partition
mkfs.ext4 ${DEVICE}2

# mount it to /mnt
mount ${DEVICE}2 /mnt


# install the base packages
pacstrap /mnt base


# generate /etc/fstab
genfstab -U /mnt >> /mnt/etc/fstab


# => chroot into new system


# install grub
arch-chroot /mnt pacman -Syu --noconfirm grub
arch-chroot /mnt grub-install --target=i386-pc ${DEVICE}

# skip grub menu if *not holding shift*
echo 'GRUB_FORCE_HIDDEN_MENU="true"' >> /mnt/etc/default/grub
curl -o /mnt/etc/grub.d/31_hold_shift https://raw.githubusercontent.com/WhyNotHugo/grub-holdshift/master/31_hold_shift
chmod a+x /mnt/etc/grub.d/31_hold_shift

# generate grub config
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

# enable dhcpcd
arch-chroot /mnt dhcpcd
arch-chroot /mnt systemctl enable dhcpcd
