#!/bin/bash

# Parse arguments. Generated by parse-options.sh
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then domain="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --project-name=*) project_name="${1#*=}"; shift ;;
        --project-name) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then project_name="$2"; shift; fi; shift ;;
        --root-sure) root_sure=1; shift ;;
        --[^-]*) shift ;;
        *) _new_arguments+=("$1"); shift ;;
    esac
done
set -- "${_new_arguments[@]}"
unset _new_arguments

# Common Functions.
red() { echo -ne "\e[91m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
green() { echo -ne "\e[92m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
yellow() { echo -ne "\e[93m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
blue() { echo -ne "\e[94m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
magenta() { echo -ne "\e[95m" >&2; echo -n "$@" >&2; echo -ne "\e[39m" >&2; }
error() { echo -n "$INDENT" >&2; red '#' "$@" >&2; echo >&2; }
success() { echo -n "$INDENT" >&2; green '#' "$@" >&2; echo >&2; }
chapter() { echo -n "$INDENT" >&2; yellow '#' "$@" >&2; echo >&2; }
title() { echo -n "$INDENT" >&2; blue '#' "$@" >&2; echo >&2; }
code() { echo -n "$INDENT" >&2; magenta "$@" >&2; echo >&2; }
x() { echo >&2; exit 1; }
e() { echo -n "$INDENT" >&2; echo "#" "$@" >&2; }
_() { echo -n "$INDENT" >&2; echo -n "#" "$@" >&2; }
_,() { echo -n "$@" >&2; }
_.() { echo >&2; }
__() { echo -n "$INDENT" >&2; echo -n "#" '    ' >&2; [ -n "$1" ] && echo "$@" >&2 || echo -n  >&2; }
____() { echo >&2; [ -n "$delay" ] && sleep "$delay"; }

# Functions.
printVersion() {
    echo '0.11.8'
}
printHelp() {
    title RCM Drupal Adjust File System
    _ 'Variation '; yellow Outside Web Root; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << 'EOF'
Usage: rcm-drupal-adjust-file-system-outside-web-root

Options:
   --project-name *
        Set the project name. Values available from command: ls-drupal().
   --domain *
        Set the domain name. Values available from command: ls-drupal([--project-name]).

Global Options:
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.
   --root-sure
        Bypass root checking.

Environment Variables:
   PREFIX_MASTER
        Default to /usr/local/share/drupal
   PROJECTS_CONTAINER_MASTER
        Default to projects

Dependency:
   ls-drupal
   sudo
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { echo -e "\e[91m""Unable to proceed, "'`'"${line}"'`'" command not found." "\e[39m"; exit 1; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

# Functions.
isDirExists() {
    # global used:
    # global modified: found, notfound
    # function used: __
    found=
    notfound=
    if [ -d "$1" ];then
        __ Direktori '`'$(basename "$1")'`' ditemukan.
        found=1
    else
        __ Direktori '`'$(basename "$1")'`' tidak ditemukan.
        notfound=1
    fi
}
dirMustExists() {
    # global used:
    # global modified:
    # function used: __, success, error, x
    if [ -d "$1" ];then
        __; green Direktori '`'$(basename "$1")'`' ditemukan.; _.
    else
        __; red Direktori '`'$(basename "$1")'`' tidak ditemukan.; x
    fi
}
ArraySearch() {
    local index match="$1"
    local source=("${!2}")
    for index in "${!source[@]}"; do
       if [[ "${source[$index]}" == "${match}" ]]; then
           _return=$index; return 0
       fi
    done
    return 1
}
isFileExists() {
    # global used:
    # global modified: found, notfound
    # function used: __
    found=
    notfound=
    if [ -f "$1" ];then
        __ File '`'$(basename "$1")'`' ditemukan.
        found=1
    else
        __ File '`'$(basename "$1")'`' tidak ditemukan.
        notfound=1
    fi
}
vercomp() {
    # https://www.google.com/search?q=bash+compare+version
    # https://stackoverflow.com/a/4025065
    if [[ $1 == $2 ]]; then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]];then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    return 0
}
backupFile() {
    local mode="$1"
    local oldpath="$2" i newpath
    i=1
    newpath="${oldpath}.${i}"
    if [ -f "$newpath" ]; then
        let i++
        newpath="${oldpath}.${i}"
        while [ -f "$newpath" ] ; do
            let i++
            newpath="${oldpath}.${i}"
        done
    fi
    case $mode in
        move)
            mv "$oldpath" "$newpath" ;;
        copy)
            local user=$(stat -c "%U" "$oldpath")
            local group=$(stat -c "%G" "$oldpath")
            cp "$oldpath" "$newpath"
            chown ${user}:${group} "$newpath"
    esac
}
link_symbolic() {
    local source="$1"
    local target="$2"
    local sudo="$3"
    local create
    _success=
    [ -e "$source" ] || { error Source not exist: $source.; x; }
    [ -n "$target" ] || { error Target not defined.; x; }
    [[ $(type -t backupFile) == function ]] || { error Function backupFile not found.; x; }

    chapter Membuat symbolic link.
    __ source: '`'$source'`'
    __ target: '`'$target'`'
    if [ -h "$target" ];then
        __ Path target saat ini sudah merupakan symbolic link: '`'$target'`'
        __; _, Mengecek apakah link merujuk ke '`'$source'`':
        _dereference=$(stat ${stat_cached} "$target" -c %N)
        match="'$target' -> '$source'"
        if [[ "$_dereference" == "$match" ]];then
            _, ' 'Merujuk.; _.
        else
            _, ' 'Tidak merujuk.; _.
            __ Melakukan backup.
            backupFile move "$target"
            create=1
        fi
    elif [ -e "$target" ];then
        __ File/directory bukan merupakan symbolic link.
        __ Melakukan backup.
        backupFile move "$target"
        create=1
    else
        create=1
    fi
    if [ -n "$create" ];then
        __ Membuat symbolic link '`'$target'`'.
        if [ -n "$sudo" ];then
            __; magenta sudo -u '"'$sudo'"' ln -s '"'$source'"' '"'$target'"'; _.
            sudo -u "$sudo" ln -s "$source" "$target"
        else
            __; magenta ln -s '"'$source'"' '"'$target'"'; _.
            ln -s "$source" "$target"
        fi
        __ Verifikasi
        if [ -h "$target" ];then
            _dereference=$(stat ${stat_cached} "$target" -c %N)
            match="'$target' -> '$source'"
            if [[ "$_dereference" == "$match" ]];then
                __; green Symbolic link berhasil dibuat.; _.
                _success=1
            else
                __; red Symbolic link gagal dibuat.; x
            fi
        fi
    fi
    ____
}

# Title.
title rcm-drupal-adjust-file-system-outside-web-root
____

# Requirement, validate, and populate value.
chapter Dump variable.
delay=.5; [ -n "$fast" ] && unset delay
PREFIX_MASTER=${PREFIX_MASTER:=/usr/local/share/drupal}
code 'PREFIX_MASTER="'$PREFIX_MASTER'"'
PROJECTS_CONTAINER_MASTER=${PROJECTS_CONTAINER_MASTER:=projects}
code 'PROJECTS_CONTAINER_MASTER="'$PROJECTS_CONTAINER_MASTER'"'
code 'project_name="'$project_name'"'
code 'domain="'$domain'"'
vercomp `stat --version | head -1 | grep -o -E '\S+$'` 8.31
if [[ $? -lt 2 ]];then
    stat_cached=' --cached=never'
else
    stat_cached=''
fi
____

if [ -z "$root_sure" ];then
    chapter Mengecek akses root.
    if [[ "$EUID" -ne 0 ]]; then
        error This script needs to be run with superuser privileges.; x
    else
        __ Privileges.
    fi
    ____
fi

chapter Mendapatkan binary drush dari project: '`'$project_name'`'.
array=(`ls-drupal`)
ArraySearch "$project_name" array[@]
reference_key="$_return"; unset _return; # Clear.
if [ -z "$reference_key" ];then
    error Project tidak ditemukan: '`'$project_name'`'. ; x
fi
array=(`ls-drupal $project_name`)
ArraySearch "$domain" array[@]
reference_key="$_return"; unset _return; # Clear.
if [ -z "$reference_key" ];then
    error Site tidak ditemukan: '`'$domain'`'. ; x
fi
target="${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_name}/drupal"
isDirExists "$target"
if [ -n "$notfound" ];then
    error Directory is not found: "$target".; x
fi
if [ -h "$target" ];then
    _dereference=$(stat ${stat_cached} "$target" -c %N)
    PROJECT_DIR=$(grep -Eo "' -> '.*'$" <<< "$_dereference" | sed -E "s/' -> '(.*)'$/\1/")
else
    PROJECT_DIR="$target"
fi
drush="${PROJECT_DIR}/vendor/bin/drush"
isFileExists "$drush"
if [ -n "$notfound" ];then
    error Binary drush is not found: "$drush".; x
fi
____

chapter Populate variable.
code PROJECT_DIR="$PROJECT_DIR"
code DRUPAL_ROOT='"$(drush --uri='$domain' status --field=root)"'
DRUPAL_ROOT="$($drush --uri=$domain status --field=root)"
code SITE_DIR='"$(drush --uri='$domain' status --field=site)"'
SITE_DIR="$($drush --uri=$domain status --field=site)"
____

chapter Mengecek file '`'settings.php'`'.
settings="${DRUPAL_ROOT}/${SITE_DIR}/settings.php"
isFileExists "$settings"
if [ -n "$notfound" ];then
    error Files is not found: "$settings".; x
fi
owner=$(stat "$settings" -c %U)
code owner="$owner"
is_settings_writed=
____

reference="$(php -r "echo serialize([
    'app_root' => '$DRUPAL_ROOT',
    'site_path' => '$SITE_DIR',
]);")"
php=$(cat << 'EOF'
function &drupal_array_get_nested_value(array &$array, array $parents, &$key_exists = NULL) {
    $ref =& $array;
    foreach ($parents as $parent) {
        if (is_array($ref) && (isset($ref[$parent]) || array_key_exists($parent, $ref))) {
            $ref =& $ref[$parent];
        }
        else {
            $key_exists = FALSE;
            $null = NULL;
            return $null;
        }
    }
    $key_exists = TRUE;
    return $ref;
}
$file = $_SERVER['argv'][1];
$array = unserialize($_SERVER['argv'][2]);
extract($array);
if (isset($app_root) && !defined('DRUPAL_ROOT')) {
    define('DRUPAL_ROOT', $app_root);
}
include($file);
$mode = $_SERVER['argv'][3];

switch ($mode) {
    case 'array_key_exists':
        $key = $_SERVER['argv'][4];
        $array = explode('][', $key);
        drupal_array_get_nested_value($settings, $array, $key_exists);
        return ($key_exists) ? exit(0) : exit(1);
        break;

    case 'get_settings':
        $key = $_SERVER['argv'][4];
        $array = explode('][', $key);
        echo drupal_array_get_nested_value($settings, $array);
        break;

    default:
        // Do something.
        break;
}

EOF
)

chapter Memeriksa variable '`'"\$settings['php_storage']['twig']['directory']"'`' pada file '`'settings.php'`'.
edit_mode=
expected_value="${PROJECT_DIR}/cache/${SITE_DIR}/php/twig"
origin_value=
if php -r "$php" "$settings" "$reference" array_key_exists 'php_storage][twig][directory';then
    origin_value=$(php -r "$php" "$settings" "$reference" get_settings 'php_storage][twig][directory')
    if [[ ! "$expected_value" == "$origin_value" ]];then
        edit_mode=modify
    fi
else
    edit_mode=append
fi
if [ -n "$edit_mode" ];then
    __ Memerlukan edit file '`'settings.php'`'.
else
    __ Tidak memerlukan edit file '`'settings.php'`'.
    __ Nilai saat ini: "$expected_value"
fi
verify=
case "$edit_mode" in
    append)
        sudo -u "$owner" chmod u+w "$settings"
        cat << EOF >> "$settings"
\$settings['php_storage']['twig']['directory'] = '$expected_value';
EOF
        verify=1
        is_settings_writed=1
        ;;
    modify)
        number=$(grep -n "^\$settings\['php_storage'\]\['twig'\]\['directory'\] = " "$settings" | head -1 | cut -d: -f1)
        sed -i "$number"'s|.*|'"\$settings\['php_storage'\]\['twig'\]\['directory'\] = '$expected_value';"'|' "$settings"
        verify=1
        is_settings_writed=1
        ;;
esac
makesure_directory_exist=
if [ -n "$verify" ];then
    current_value=$(php -r "$php" "$settings" "$reference" get_settings 'php_storage][twig][directory')
    if [[ ! "$expected_value" == "$current_value" ]];then
        __; red Gagal mengedit file '`'settings.php'`'.; x
    else
        __; green Berhasil mengedit file '`'settings.php'`'.; _.
        __ Nilai sebelumnya: "$origin_value"
        __ Nilai saat ini: "$current_value"
        makesure_directory_exist=1
    fi
fi
if [ -z "$origin_value" ];then
    # Default sama dengan public_files.
    origin_value="${SITE_DIR}/files"
    if [ ! "${origin_value:0:1}" == '/' ];then
        origin_value="${DRUPAL_ROOT}/${origin_value}"
    fi
fi
if [ -n "$makesure_directory_exist" ];then
    __ Mengecek direktori: "$expected_value"
    isDirExists "$expected_value"
    if [ -n "$notfound" ];then
        __ Mengecek direktori: "${origin_value}/php/twig"
        isDirExists "${origin_value}/php/twig"
        # x
        if [ -n "$found" ];then
            __ Memindahkan direktori.
            dirname=$(dirname "$expected_value")
            code sudo -u '"'$owner'"' mkdir -p '"'$dirname'"'
            code mv -T '"'${origin_value}/php/twig'"' '"'$expected_value'"'
            sudo -u "$owner" mkdir -p "$dirname"
            mv -T "${origin_value}/php/twig" "$expected_value"
            dirname=$(dirname "${origin_value}/php/twig")
            code rmdir --ignore-fail-on-non-empty '"'$dirname'"'
            rmdir --ignore-fail-on-non-empty "$dirname"
            dirMustExists "$expected_value"
        fi
    fi
fi
____

chapter Memeriksa variable '`'"\$settings['config_sync_directory']"'`' pada file '`'settings.php'`'.
edit_mode=
expected_config="${PROJECT_DIR}/config/${SITE_DIR}/sync"
origin_config=
if php -r "$php" "$settings" "$reference" array_key_exists config_sync_directory;then
    origin_config=$(php -r "$php" "$settings" "$reference" get_settings config_sync_directory)
    if [[ ! "$expected_config" == "$origin_config" ]];then
        edit_mode=modify
    fi
else
    edit_mode=append
fi
if [ -n "$edit_mode" ];then
    __ Memerlukan edit file '`'settings.php'`'.
else
    __ Tidak memerlukan edit file '`'settings.php'`'.
    __ Nilai saat ini: "$expected_config"
fi
verify=
case "$edit_mode" in
    append)
        sudo -u "$owner" chmod u+w "$settings"
        cat << EOF >> "$settings"
\$settings['config_sync_directory'] = '$expected_config';
EOF
        verify=1
        is_settings_writed=1
        ;;
    modify)
        number=$(grep -n "^\$settings\['config_sync_directory'\] = " "$settings" | head -1 | cut -d: -f1)
        sed -i "$number"'s|.*|'"\$settings\['config_sync_directory'\] = '$expected_config';"'|' "$settings"
        verify=1
        is_settings_writed=1
        ;;
esac
makesure_directory_exist=
if [ -n "$verify" ];then
    current_config=$(php -r "$php" "$settings" "$reference" get_settings config_sync_directory)
    if [[ ! "$expected_config" == "$current_config" ]];then
        __; red Gagal mengedit file '`'settings.php'`'.; x
    else
        __; green Berhasil mengedit file '`'settings.php'`'.; _.
        __ Nilai sebelumnya: "$origin_config"
        __ Nilai saat ini: "$current_config"
        makesure_directory_exist=1
    fi
fi
if [ -n "$makesure_directory_exist" ];then
    __ Mengecek direktori: "$expected_config"
    isDirExists "$expected_config"
    create=
    if [ -n "$notfound" ];then
        if [ -n "$origin_config" ];then
            if [ ! "${origin_config:0:1}" == '/' ];then
                origin_config="${DRUPAL_ROOT}/${origin_config}"
            fi
            __ Mengecek direktori: "$origin_config"
            isDirExists "$origin_config"
            if [ -n "$found" ];then
                __ Memindahkan direktori.
                dirname=$(dirname "$expected_config")
                code sudo -u '"'$owner'"' mkdir -p '"'$dirname'"'
                code mv -T '"'$origin_config'"' '"'$expected_config'"'
                sudo -u "$owner" mkdir -p "$dirname"
                mv -T "$origin_config" "$expected_config"
                dirname=$(dirname "$origin_config")
                code rmdir --ignore-fail-on-non-empty '"'$dirname'"'
                rmdir --ignore-fail-on-non-empty "$dirname"
                dirMustExists "$expected_config"
            else
                create=1
            fi
        else
            create=1
        fi
    fi
    if [ -n "$create" ];then
        code sudo -u '"'$owner'"' mkdir -p '"'$expected_config'"'
        sudo -u "$owner" mkdir -p "$expected_config"
        dirMustExists "$expected_config"
    fi
fi
____

chapter Memeriksa variable '`'"\$settings['file_private_path']"'`' pada file '`'settings.php'`'.
edit_mode=
expected_private="${PROJECT_DIR}/private/${SITE_DIR}/files"
origin_private=
if php -r "$php" "$settings" "$reference" array_key_exists file_private_path;then
    origin_private=$(php -r "$php" "$settings" "$reference" get_settings file_private_path)
    if [[ ! "$expected_private" == "$origin_private" ]];then
        edit_mode=modify
    fi
else
    edit_mode=append
fi
if [ -n "$edit_mode" ];then
    __ Memerlukan edit file '`'settings.php'`'.
else
    __ Tidak memerlukan edit file '`'settings.php'`'.
    __ Nilai saat ini: "$expected_private"
fi
verify=
case "$edit_mode" in
    append)
        sudo -u "$owner" chmod u+w "$settings"
        cat << EOF >> "$settings"
\$settings['file_private_path'] = '$expected_private';
EOF
        verify=1
        is_settings_writed=1
        ;;
    modify)
        number=$(grep -n "^\$settings\['file_private_path'\] = " "$settings" | head -1 | cut -d: -f1)
        sed -i "$number"'s|.*|'"\$settings\['file_private_path'\] = '$expected_private';"'|' "$settings"
        verify=1
        is_settings_writed=1
        ;;
esac
makesure_directory_exist=
if [ -n "$verify" ];then
    current_private=$(php -r "$php" "$settings" "$reference" get_settings file_private_path)
    if [[ ! "$expected_private" == "$current_private" ]];then
        __; red Gagal mengedit file '`'settings.php'`'.; x
    else
        __; green Berhasil mengedit file '`'settings.php'`'.; _.
        __ Nilai sebelumnya: "$origin_private"
        __ Nilai saat ini: "$current_private"
        makesure_directory_exist=1
    fi
fi
if [ -n "$makesure_directory_exist" ];then
    __ Mengecek direktori: "$expected_private"
    isDirExists "$expected_private"
    create=
    if [ -n "$notfound" ];then
        if [ -n "$origin_private" ];then
            if [ ! "${origin_private:0:1}" == '/' ];then
                origin_private="${DRUPAL_ROOT}/${origin_private}"
            fi
            __ Mengecek direktori: "$origin_private"
            isDirExists "$origin_private"
            if [ -n "$found" ];then
                __ Memindahkan direktori.
                dirname=$(dirname "$expected_private")
                code sudo -u '"'$owner'"' mkdir -p '"'$dirname'"'
                code mv -T '"'$origin_private'"' '"'$expected_private'"'
                sudo -u "$owner" mkdir -p "$dirname"
                mv -T "$origin_private" "$expected_private"
                dirname=$(dirname "$origin_private")
                dirMustExists "$expected_private"
            else
                create=1
            fi
        else
            create=1
        fi
    fi
    if [ -n "$create" ];then
        code sudo -u '"'$owner'"' mkdir -p '"'$expected_private'"'
        sudo -u "$owner" mkdir -p "$expected_private"
        dirMustExists "$expected_private"
    fi
fi
____

chapter Memeriksa variable '`'"\$settings['file_public_path']"'`' pada file '`'settings.php'`'.
edit_mode=
expected_value="${SITE_DIR}/files"
expected_value_realpath="${PROJECT_DIR}/public/${SITE_DIR}/files"
origin_value=
if php -r "$php" "$settings" "$reference" array_key_exists file_public_path;then
    origin_value=$(php -r "$php" "$settings" "$reference" get_settings file_public_path)
    if [[ ! "$expected_value" == "$origin_value" ]];then
        edit_mode=modify
    fi
else
    edit_mode=append
fi
if [ -n "$edit_mode" ];then
    __ Memerlukan edit file '`'settings.php'`'.
else
    __ Tidak memerlukan edit file '`'settings.php'`'.
    __ Nilai saat ini: "$expected_value"
fi
verify=
case "$edit_mode" in
    append)
        sudo -u "$owner" chmod u+w "$settings"
        cat << EOF >> "$settings"
\$settings['file_public_path'] = '$expected_value';
EOF
        verify=1
        is_settings_writed=1
        ;;
    modify)
        number=$(grep -n "^\$settings\['file_public_path'\] = " "$settings" | head -1 | cut -d: -f1)
        sed -i "$number"'s|.*|'"\$settings\['file_public_path'\] = '$expected_value';"'|' "$settings"
        verify=1
        is_settings_writed=1
        ;;
esac
makesure_directory_exist=
if [ -n "$verify" ];then
    current_value=$(php -r "$php" "$settings" "$reference" get_settings file_public_path)
    if [[ ! "$expected_value" == "$current_value" ]];then
        __; red Gagal mengedit file '`'settings.php'`'.; x
    else
        __; green Berhasil mengedit file '`'settings.php'`'.; _.
        __ Nilai sebelumnya: "$origin_value"
        __ Nilai saat ini: "$current_value"
        makesure_directory_exist=1
    fi
fi
if [ -z "$origin_value" ];then
    origin_value="$expected_value"
    if [ ! "${origin_value:0:1}" == '/' ];then
        origin_value="${DRUPAL_ROOT}/${origin_value}"
    fi
fi
origin_value_realpath="$origin_value"
if [ -h "$origin_value_realpath" ];then
    _dereference=$(stat ${stat_cached} "$origin_value_realpath" -c %N)
    origin_value_realpath=$(grep -Eo "' -> '.*'$" <<< "$_dereference" | sed -E "s/' -> '(.*)'$/\1/")
fi
if [ -n "$makesure_directory_exist" ];then
    __ Mengecek direktori: "$expected_value_realpath"
    isDirExists "$expected_value_realpath"
    if [ -n "$notfound" ];then
        __ Mengecek direktori: "$origin_value_realpath"
        isDirExists "$origin_value_realpath"
        if [ -n "$found" ];then
            __ Memindahkan direktori.
            dirname=$(dirname "$expected_value_realpath")
            code sudo -u '"'$owner'"' mkdir -p '"'$dirname'"'
            code mv -T '"'$origin_value_realpath'"' '"'$expected_value_realpath'"'
            sudo -u "$owner" mkdir -p "$dirname"
            mv -T "$origin_value_realpath" "$expected_value_realpath"
            dirname=$(dirname "$origin_value_realpath")
            dirMustExists "$expected_value_realpath"
        fi
    fi
fi
____

dirname=$(dirname "${DRUPAL_ROOT}/${expected_value}")
chmod u+w "$dirname"
link_symbolic "$expected_value_realpath" "${DRUPAL_ROOT}/${expected_value}" "$owner"
chapter Memeriksa variable '`'"\$settings['file_assets_path']"'`' pada file '`'settings.php'`'.
edit_mode=
expected_value="${SITE_DIR}/assets"
expected_value_realpath="${PROJECT_DIR}/assets/${SITE_DIR}/files"
origin_value=
if php -r "$php" "$settings" "$reference" array_key_exists file_assets_path;then
    origin_value=$(php -r "$php" "$settings" "$reference" get_settings file_assets_path)
    if [[ ! "$expected_value" == "$origin_value" ]];then
        edit_mode=modify
    fi
else
    edit_mode=append
fi
if [ -n "$edit_mode" ];then
    __ Memerlukan edit file '`'settings.php'`'.
else
    __ Tidak memerlukan edit file '`'settings.php'`'.
    __ Nilai saat ini: "$expected_value"
fi
verify=
case "$edit_mode" in
    append)
        sudo -u "$owner" chmod u+w "$settings"
        cat << EOF >> "$settings"
\$settings['file_assets_path'] = '$expected_value';
EOF
        verify=1
        is_settings_writed=1
        ;;
    modify)
        number=$(grep -n "^\$settings\['file_assets_path'\] = " "$settings" | head -1 | cut -d: -f1)
        sed -i "$number"'s|.*|'"\$settings\['file_assets_path'\] = '$expected_value';"'|' "$settings"
        verify=1
        is_settings_writed=1
        ;;
esac
makesure_directory_exist=
if [ -n "$verify" ];then
    current_value=$(php -r "$php" "$settings" "$reference" get_settings file_assets_path)
    if [[ ! "$expected_value" == "$current_value" ]];then
        __; red Gagal mengedit file '`'settings.php'`'.; x
    else
        __; green Berhasil mengedit file '`'settings.php'`'.; _.
        __ Nilai sebelumnya: "$origin_value"
        __ Nilai saat ini: "$current_value"
        makesure_directory_exist=1
    fi
fi
if [ -z "$origin_value" ];then
    # Default sama dengan public_files.
    origin_value="${SITE_DIR}/files"
    if [ ! "${origin_value:0:1}" == '/' ];then
        origin_value="${DRUPAL_ROOT}/${origin_value}"
    fi
fi
origin_value_realpath="$origin_value"
if [ -h "$origin_value_realpath" ];then
    _dereference=$(stat ${stat_cached} "$origin_value_realpath" -c %N)
    origin_value_realpath=$(grep -Eo "' -> '.*'$" <<< "$_dereference" | sed -E "s/' -> '(.*)'$/\1/")
fi
if [ -n "$makesure_directory_exist" ];then
    __ Mengecek direktori: "$expected_value_realpath"
    isDirExists "$expected_value_realpath"
    if [ -n "$notfound" ];then
        code sudo -u '"'$owner'"' mkdir -p '"'$expected_value_realpath'"'
        sudo -u "$owner" mkdir -p "$expected_value_realpath"
        dirMustExists "$expected_value_realpath"
    fi
    for each in js css; do
        __ Mengecek direktori: "$expected_value_realpath"/"$each"
        isDirExists "$expected_value_realpath"/"$each"
        if [ -n "$notfound" ];then
            __ Mengecek direktori: "$origin_value_realpath"/"$each"
            isDirExists "$origin_value_realpath"/"$each"
            if [ -n "$found" ];then
                __ Memindahkan direktori.
                dirname=$(dirname "$expected_value_realpath"/"$each")
                code sudo -u '"'$owner'"' mkdir -p '"'$dirname'"'
                code mv -T '"'$origin_value_realpath/$each'"' '"'$expected_value_realpath/$each'"'
                sudo -u "$owner" mkdir -p "$dirname"
                mv -T "$origin_value_realpath"/"$each" "$expected_value_realpath"/"$each"
                dirname=$(dirname "$origin_value_realpath"/"$each")
                dirMustExists "$expected_value_realpath"/"$each"
            fi
        fi
    done
fi
____

dirname=$(dirname "${DRUPAL_ROOT}/${expected_value}")
chmod u+w "$dirname"
link_symbolic "$expected_value_realpath" "${DRUPAL_ROOT}/${expected_value}" "$owner"

if [ -n "$is_settings_writed" ];then
    chapter Cache Rebuild
    code drush cache:rebuild
    $drush cache:rebuild
    ____
fi

exit 0

# parse-options.sh \
# --without-end-options-double-dash \
# --compact \
# --clean \
# --no-hash-bang \
# --no-original-arguments \
# --no-error-invalid-options \
# --no-error-require-arguments << EOF | clip
# FLAG=(
# --fast
# --version
# --help
# --root-sure
# )
# VALUE=(
# --project-name
# --domain
# )
# FLAG_VALUE=(
# )
# EOF
