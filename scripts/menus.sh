#!/usr/bin/env bash

chech_as_root() {
    if [[ "$EUID" != 0 ]]
        then 
                whiptail --clear --msgbox "It should run as root, can't install" --title "Run as ${USERNAME}" 7 45 3>&1 1>&2 2>&3
                exit 1
    fi
}

check_arch_iso() {
    if [[ $(command -v pacstrap) ]]
        then
                whiptail --clear --msgbox "Arch Linux ISO not mounted, can't install" --title "Arch ISO error" 7 45 3>&1 1>&2 2>&3
                exit 1
    fi    
}


install_ok() {
    if ! (whiptail --clear --defaultno --yesno "This will install Arch. Are you sure ?" --title "Arch installation" 7 42 3>&1 1>&2 2>&3) 
        then
            exit 1
    fi
}


set_keyboard() {

    loadkeys us

    key_maps=$(find /usr/share/kbd/keymaps -type f | sed -n -e 's!^.*/!!p' | grep ".map.gz" | sed 's/.map.gz//g' | sed 's/$/ -/g' | sort)
    while (true)
        do
            KEYBOARD=$(whiptail --clear --nocancel --menu "Choose a layout" --title "Keyboard layout" 18 60 10 \
            "us" "United States" \
            "de" "German" \
            "el" "Greek" \
            "hu" "Hungarian" \
            "es" "Spanish" \
            "fr" "French" \
            "it" "Italian" \
            "pt-latin9" "Portugal" \
            "ro" "Romanian" \
            "ru" "Russian" \
            "sv" "Swedish" \
            "uk" "United Kingdom" \
            "other" "Other" 3>&1 1>&2 2>&3)

            if [[ "${KEYBOARD}" == other ]]; then
                KEYBOARD=$(whiptail --clear --menu "Choose a layout" --title "Keyboard layout" 19 60 10  "$key_maps" 3>&1 1>&2 2>&3)
                if [[ "$?" == 0 ]]; then
                    break
                fi
            else
                break
            fi
        done

    loadkeys "${KEYBOARD}"

    TEST_KEYBOARD=$(whiptail --clear --cancel-button "Choose another layout" --inputbox "Is the new layout ok ?" 8 78 --title "Keyboard layout" 3>&1 1>&2 2>&3)
    if [[ "$?" == 1 ]]
        then
            set_keyboard
        fi

}

set_timezone() {

    zonelist=$(find /usr/share/zoneinfo -maxdepth 1 | sed -n -e 's!^.*/!!p' | grep -v "posix\|right\|zoneinfo\|zone.tab\|zone1970.tab\|W-SU\|WET\|posixrules\|MST7MDT\|iso3166.tab\|CST6CDT" | sort | sed 's/$/ -/g')

    while (true)
        do
        
        ZONE=$(whiptail --clear --nocancel --menu "Choose your timezone" 19 60 11 "$zonelist" 3>&1 1>&2 2>&3)
        if (find /usr/share/zoneinfo -maxdepth 1 -type d | sed -n -e 's!^.*/!!p' | grep "$ZONE" &> /dev/null); then
            sublist=$(find /usr/share/zoneinfo/"$ZONE" -maxdepth 1 | sed -n -e 's!^.*/!!p' | sort | sed 's/$/ -/g' | grep -v "$ZONE")
            SUBZONE=$(whiptail --clear --cancel-button "Back" --menu "Choose your zone" 18 60 11 "$sublist" 3>&1 1>&2 2>&3)
            if [[ "$?" == 0 ]]; then
                if (find /usr/share/zoneinfo/"$ZONE" -maxdepth 1 -type  d | sed -n -e 's!^.*/!!p' | grep "$SUBZONE" &> /dev/null); then
                    sublist=$(find /usr/share/zoneinfo/"$ZONE"/"$SUBZONE" -maxdepth 1 | sed -n -e 's!^.*/!!p' | sort | sed 's/$/ -/g' | grep -v "$SUBZONE")
                    SUB_SUBZONE=$(whiptail --clear --cancel-button "Back" --menu "Choose your sub zone" 15 60 7 "$sublist" 3>&1 1>&2 2>&3)
                    if [[ "$?" == 0 ]]; then
                        ZONE="${ZONE}/${SUBZONE}/${SUB_SUBZONE}"
                        break
                    fi
                else
                    ZONE="${ZONE}/${SUBZONE}"
                    break
                fi
            fi
        else
            break
        fi
    done
}

set_hostname() {
    while (true)
    do
        HOSTNAME=$(whiptail --clear --nocancel --inputbox "Enter the hostname ?" 8 78 --title "Hostname" 3>&1 1>&2 2>&3)
        [[ "$?" == 0 && "${HOSTNAME}" != "" ]] && break
    done
}


set_username() {
    while (true)
    do
        USERNAME=$(whiptail --clear --nocancel --inputbox "Choose a username" 8 78 "${DEFAULT_SWAP_SIZE}" --title "User name" 3>&1 1>&2 2>&3)
        if [[ "$?" == 0 &&  -n "${USERNAME##*[!0-9a-zA-Z]*}" ]]
            then
                break
            fi
    done
}


set_password() {
    while (true)
        do
            PASSWORD=$(whiptail --clear --nocancel --passwordbox "Enter your password" 8 78 --title "Password" 3>&1 1>&2 2>&3)
            if [[ "$?" == 0 && "${PASSWORD}" != "" ]]
                then
                    REPASSWORD=$(whiptail --clear --passwordbox "Re-type your password" 8 78 --title "Confirm password" 3>&1 1>&2 2>&3)
                    if [[ "$?" == 0 ]]
                        then
                            if [ "${PASSWORD}" == "${REPASSWORD}" ]
                                then
                                    break
                                fi
                        fi
                fi
        done
}

set_disk() {

    disks=$(lsblk -nio NAME,SIZE,TYPE | grep -E "disk|raid[0-9]+$" | column -t | uniq | awk '{ print "\"" $1 "\" \"    (" $2 ")\"" }' | column -t)
    DISK=$(echo "$disks" | xargs whiptail --clear --nocancel --title "Disk installation" --menu "Choose a disk" 15 70 4 3>&1 1>&2 2>&3)    

    if [[ ${DISK} == nvme* ]]
        then
            DISK_PREFIX="${DISK}p"
        else 
            DISK_PREFIX="${DISK}"
        fi

}

set_swap() {
    while (true)
    do
        RAM_SIZE=$(free --giga | head -n 2 | tail -n 1 | awk '{ print $2 }')
        DEFAULT_SWAP_SIZE=$((RAM_SIZE + 1))
        INPUT_SWAP_SIZE=${SWAP_SIZE:=$DEFAULT_SWAP_SIZE}
        SWAP_SIZE=$(whiptail --clear --nocancel --inputbox "Enter the swap size in Go" 8 78 ${INPUT_SWAP_SIZE} --title "Swap partition" 3>&1 1>&2 2>&3)
        [[ "$?" == 0 && -n "${SWAP_SIZE##*[!0-9]*}" && ${SWAP_SIZE} -gt 0 ]] && break
    done
}

set_ucode() {
    if (( $(grep -ci intel /proc/cpuinfo) > 0 ))
        then
            UCODE_PKG=intel-ucode
        fi

    if (( $(grep -ci amd /proc/cpuinfo) > 0 ))
        then
            UCODE_PKG=amd-ucode
        fi

    if $(whiptail --clear --yesno "Do you want to install ${UCODE_PKG} ?" --title "Ucode installation" 7 42 3>&1 1>&2 2>&3)
        then
            INSTALL_UCODE="Yes"
        else
            INSTALL_UCODE="No"
    fi
}

set_fastgrub() {
    if $(whiptail --clear --yesno "Do you want to hide grub ?" --title "GRUB installation" 7 42 3>&1 1>&2 2>&3)
        then
            FAST_GRUB="Yes"
        else
            FAST_GRUB="No"
    fi

}

set_yay() {
    if $(whiptail --clear --yesno "Do you want to install yay ?" --title "YAY installation" 7 42 3>&1 1>&2 2>&3)
        then
            INSTALL_YAY="Yes"
        else
            INSTALL_YAY="No"
    fi

}

change_menu() {

    while (true)
    do
        MENU_OPTION=$(whiptail --clear --cancel-button "Abort Installation" --title "Installation" --menu "Choose an option" 25 75 16 \
                        "Change Keyboard"    "    ${KEYBOARD}" \
                        "Change Timezone"    "    ${ZONE}" \
                        "Change Hostname"    "    ${HOSTNAME}" \
                        "Change Username"    "    ${USERNAME}" \
                        "Change Password"    "    $(echo "$PASSWORD" | sed "s/./\*/g")" \
                        "Change Disk"        "    ${DISK}" \
                        "Change Swap"        "    ${SWAP_SIZE} Go" \
                        "Install ucode"      "    ${INSTALL_UCODE}" \
                        "Fast GRUB"          "    ${FAST_GRUB}" \
                        "Install yay"        "    ${INSTALL_YAY}" \
                        "" "" \
                        "Install Arch Linux" "" \
                        3>&1 1>&2 2>&3)

        [[ "$?" == 1 ]] && exit 1

        case "${MENU_OPTION}" in
            "Change Keyboard")
                    set_keyboard
            ;;
            "Change Timezone")
                    set_timezone
            ;;
            "Change Hostname")
                    set_hostname
            ;;
            "Change Username")
                    set_username
            ;;
            "Change Password")
                    set_password
            ;;
            "Change Disk")
                    set_disk
            ;;
            "Change Swap")
                    set_swap
            ;;
            "Install ucode")
                    set_ucode
            ;;
            "Fast GRUB")
                    set_fastgrub
            ;;
            "Install yay")
                    set_yay
            ;;
            "Install Arch Linux")
                    break
            ;;
        esac
    done
}
