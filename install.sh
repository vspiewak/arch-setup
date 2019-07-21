#!/bin/bash

EFI_VARS_FILE=/sys/firmware/efi/efivars
TGTDEV=/dev/sda


echo "Installing Arch"

# check boot mode
if test -f "${EFI_VARS_FILE}"; then
  echo "Boot Mode: UEFI"
else
  echo "Boot Mode: BIOS"
fi

timedatectl set-ntp true
timedatectl set-timezone Europe/Paris

# to create the partitions programatically (rather than manually)
# we're going to simulate the manual input to fdisk
# The sed script strips off all the comments so that we can
# document what we're doing in-line with the actual commands
# Note that a blank line (commented as "defualt" will send a empty
# line terminated with a newline to take the fdisk default.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${TGTDEV}
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
  +300M # 300 MB boot parttion
  n # new partition
  p # primary partition
  2 # partition number 2
    # default - start at beginning of disk
  +2G # 2G swap parttion
  n # new partition
  p # primary partition
  3 # partion number 3
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
  a # make a partition bootable
  1 # bootable partition is partition 1 -- /dev/sda1
  t # change partition type to efi
  1 # swap partition is partition 1 -- /dev/sda1
  ef # type efi
  t # change partition type to swap
  2 # swap partition is partition 2 -- /dev/sda2
  82 # type swap
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

# boot partition
mkfs.fat -F32 /dev/sda1

# swap partition
mkswap /dev/sda2
swapon /dev/sda2

# root partition
mkfs.ext4 /dev/sda3

# mount / to /mnt
mount /dev/sda3 /mnt

# mount /boot to /mnt/boot
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot


# install the base packages
pacstrap /mnt base

# generate /etc/fstab
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

# chroot into new system
arch-chroot /mnt
