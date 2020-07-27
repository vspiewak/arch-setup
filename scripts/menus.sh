#!/usr/bin/env bash

chech_as_root() {
    if [ "$EUID" -ne 0 ]
        then 
                whiptail --clear --msgbox "It should run as root, can't install" --title "Run as ${USERNAME}" 7 45 3>&1 1>&2 2>&3
                exit 1
    fi
}

check_arch_iso() {
    command -v pacstrap
    if [ "$?" -ne "0" ]
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

            if [ "${KEYBOARD}" = "other" ]; then
                KEYBOARD=$(whiptail --clear --menu "Choose a layout" --title "Keyboard layout" 19 60 10  $key_maps 3>&1 1>&2 2>&3)
                if [ "$?" -eq "0" ]; then
                    break
                fi
            else
                break
            fi
        done

    loadkeys ${KEYBOARD}

    TEST_KEYBOARD=$(whiptail --clear --cancel-button "Choose another layout" --inputbox "Is the new layout ok ?" 8 78 --title "Keyboard layout" 3>&1 1>&2 2>&3)
    if [ "$?" -eq "1" ]
        then
            set_keyboard
        fi

}

set_locale() {

    localelist=$(grep -E "^#?[a-z].*UTF-8" /etc/locale.gen | sed 's/#//' | awk '{print $1" -"}')
    
    while (true)
      do
        LOCALE=$(whiptail --clear --nocancel --menu "Choose your locale" 18 60 11 \
        "en_US.UTF-8" "United States" \
        "en_AU.UTF-8" "Australia" \
        "pt_BR.UTF-8" "Brazil" \
        "en_CA.UTF-8" "Canada" \
        "es_ES.UTF-8" "Spanish" \
        "fr_FR.UTF-8" "French" \
        "de_DE.UTF-8" "German" \
        "el_GR.UTF-8" "Greek" \
        "en_GB.UTF-8" "Great Britain" \
        "hu_HU.UTF-8" "Hungary" \
        "it_IT.UTF-8" "Italian" \
        "lv_LV.UTF-8" "Latvian" \
        "es_MX.UTF-8" "Mexico" \
        "pt_PT.UTF-8" "Portugal" \
        "ro_RO.UTF-8" "Romanian" \
        "ru_RU.UTF-8" "Russian" \
        "es_ES.UTF-8" "Spanish" \
        "sv_SE.UTF-8" "Swedish" \
        "other"       "Other" 3>&1 1>&2 2>&3)

        if [ "$LOCALE" = "other" ]; then
            LOCALE=$(whiptail --clear --cancel-button "Back" --menu "Choose your locale" 18 60 11 $localelist 3>&1 1>&2 2>&3)
            if [ "$?" -eq "0" ]; then
                break
            fi
        else
            break
        fi
    done

}

set_timezone() {

    zonelist=$(find /usr/share/zoneinfo -maxdepth 1 | sed -n -e 's!^.*/!!p' | grep -v "posix\|right\|zoneinfo\|zone.tab\|zone1970.tab\|W-SU\|WET\|posixrules\|MST7MDT\|iso3166.tab\|CST6CDT" | sort | sed 's/$/ -/g')

    while (true)
        do
        
        ZONE=$(whiptail --clear --nocancel --menu "Choose your timezone" 19 60 11 $zonelist 3>&1 1>&2 2>&3)
        if (find /usr/share/zoneinfo -maxdepth 1 -type d | sed -n -e 's!^.*/!!p' | grep "$ZONE" &> /dev/null); then
            sublist=$(find /usr/share/zoneinfo/"$ZONE" -maxdepth 1 | sed -n -e 's!^.*/!!p' | sort | sed 's/$/ -/g' | grep -v "$ZONE")
            SUBZONE=$(whiptail --clear --cancel-button "Back" --menu "Choose your zone" 18 60 11 $sublist 3>&1 1>&2 2>&3)
            if [ "$?" -eq "0" ]; then
                if (find /usr/share/zoneinfo/"$ZONE" -maxdepth 1 -type  d | sed -n -e 's!^.*/!!p' | grep "$SUBZONE" &> /dev/null); then
                    sublist=$(find /usr/share/zoneinfo/"$ZONE"/"$SUBZONE" -maxdepth 1 | sed -n -e 's!^.*/!!p' | sort | sed 's/$/ -/g' | grep -v "$SUBZONE")
                    SUB_SUBZONE=$(whiptail --clear --cancel-button "Back" --menu "Choose your sub zone" 15 60 7 $sublist 3>&1 1>&2 2>&3)
                    if [ "$?" -eq "0" ]; then
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
        if [ "$?" -eq "0" ] && [ "${HOSTNAME}" != "" ]
            then
                break
            fi
    done
}


set_username() {
    while (true)
    do
        USERNAME=$(whiptail --clear --nocancel --inputbox "Choose a username" 8 78 ${DEFAULT_SWAP_SIZE} --title "User name" 3>&1 1>&2 2>&3)
        if [ "$?" -eq "0" ] && [ ! -z "${USERNAME##*[!0-9a-zA-Z]*}" ]
            then
                break
            fi
    done
}


set_password() {
    while (true)
        do
            PASSWORD=$(whiptail --clear --nocancel --passwordbox "Enter your password" 8 78 --title "Password" 3>&1 1>&2 2>&3)
            if [ "$?" -eq "0" ] && [ "${PASSWORD}" != "" ]
                then
                    
                    REPASSWORD=$(whiptail --clear --passwordbox "Re-type your password" 8 78 --title "Confirm password" 3>&1 1>&2 2>&3)
                    if [ "$?" == "0" ]
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

    disks=$(lsblk -nio NAME,SIZE,TYPE | egrep "disk|raid[0-9]+$" | column -t | uniq | awk '{ print "\"" $1 "\" \"    (" $2 ")\"" }' | column -t)
    DISK=$(echo $disks | xargs whiptail --clear --nocancel --title "Disk installation" --menu "Choose a disk" 15 70 4 3>&1 1>&2 2>&3)    

    if [[ ${DISK} == "nvme*" ]]
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
        if [ "$?" -eq "0" ] && [ ! -z "${SWAP_SIZE##*[!0-9]*}" ] && [ ${SWAP_SIZE} -gt 0 ]
            then
                break
            fi
    done
}

set_ucode() {
    if (( $(cat /proc/cpuinfo | grep -i intel | wc -l) > 0 ))
        then
            UCODE_PKG=intel-ucode
        fi

    if (( $(cat /proc/cpuinfo | grep -i amd | wc -l) > 0 ))
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
                        "Change Locale"      "    ${LOCALE}" \
                        "Change Timezone"    "    ${ZONE}" \
                        "Change Hostname"    "    ${HOSTNAME}" \
                        "Change Username"    "    ${USERNAME}" \
                        "Change Password"    "    $(echo $PASSWORD | sed "s/./\*/g")" \
                        "Change Disk"        "    ${DISK}" \
                        "Change Swap"        "    ${SWAP_SIZE} Go" \
                        "Install ucode"      "    ${INSTALL_UCODE}" \
                        "Fast GRUB"          "    ${FAST_GRUB}" \
                        "Install yay"        "    ${INSTALL_YAY}" \
                        "" "" \
                        "Install Arch Linux" "" \
                        3>&1 1>&2 2>&3)

        if [ "$?" -eq "1" ]
            then
                exit 1
            fi

        case "${MENU_OPTION}" in
            "Change Keyboard")
                    set_keyboard
            ;;
            "Change Locale")
                    set_locale
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
