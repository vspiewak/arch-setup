#!/usr/bin/env bash

run_bootstrap() {
    chech_as_root
    check_arch_iso
    install_ok
    set_keyboard
    set_locale
    set_timezone
    set_hostname
    set_username
    set_password
    set_disk
    set_swap
    set_ucode
    set_fastgrub
    set_yay
    change_menu
    bootstrap
}