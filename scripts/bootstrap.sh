echo 'bootsrap'

pwd
ls -al *.sh

for script in "*.sh" ; do
    [[ -e "${script}" ]] || break
    source "${script}"
done

chech_as_root