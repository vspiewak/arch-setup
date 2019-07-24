#!/usr/bin/env bash

{ # this ensures the entire script is downloaded #

  GITHUB_ACCOUNT=vspiewak
  GITHUB_PROJECT=arch-setup

  ARCH_LIVE_DIR=/run/archiso/cowspace

  ARCHIVE_URI="https://github.com/${GITHUB_ACCOUNT}/${GITHUB_PROJECT}/tarball/master"

  do_install() {

    local YELLOW
    YELLOW='\033[0;33m'
    local BLUE
    BLUE='\033[0;34m'
    local GREY
    GREY='\033[0;90m'
    local NC
    NC='\033[0m'

    TMP_DIR=$(mktemp -d)

    echo -e "${GREY}[1/4]${NC} 🚚 Downloading archive"
    curl -s -L ${ARCHIVE_URI} > ${TMP_DIR}/master.tgz

    echo -e "${GREY}[2/4]${NC} 🚧 Uncompress archive"
    tar xzf ${TMP_DIR}/master.tgz --strip=1 -C ${TMP_DIR}

    # launch bootstrap or install
    if [[ ! -d "${ARCH_LIVE_DIR}" ]]
    then
      echo -e "${GREY}[3/4]${NC} 🚀 Run configuration"
      ${TMP_DIR}/configure.sh
    else
      echo -e "${GREY}[3/4]${NC} 🚀 Run bootstrap"
      ${TMP_DIR}/bootstrap.sh
    fi

    echo -e "${GREY}[4/4]${NC} 🎉 Done"

  }

  # launch install
  do_install

} # this ensures the entire script is downloaded #
