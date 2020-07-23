SCRIPTS_DIR=$(dirname "$(readlink -f "$0")")

for script in "${SCRIPTS_DIR}/*.sh" ; do
    [[ -e "${script}" ]] || break
    source "${script}"
done

chech_as_root