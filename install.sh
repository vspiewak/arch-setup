#!/bin/bash

EFI_VARS_FILE=/sys/firmware/efi/efivars

echo "Installing Arch"

# check boot mode
if test -f "${EFI_VARS_FILE}"; then
  echo "Boot Mode: UEFI"
else
  echo "Boot Mode: BIOS"
fi

timedatectl set-ntp true
timedatectl set-timezone Europe/Paris
