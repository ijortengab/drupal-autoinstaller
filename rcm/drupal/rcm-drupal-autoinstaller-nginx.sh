#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --auto-add-group) auto_add_group=1; shift ;;
        --domain-strict) domain_strict=1; shift ;;
        --drupal-version=*) drupal_version="${1#*=}"; shift ;;
        --drupal-version) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then drupal_version="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --php-fpm-user=*) php_fpm_user="${1#*=}"; shift ;;
        --php-fpm-user) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then php_fpm_user="$2"; shift; fi; shift ;;
        --php-version=*) php_version="${1#*=}"; shift ;;
        --php-version) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then php_version="$2"; shift; fi; shift ;;
        --prefix=*) prefix="${1#*=}"; shift ;;
        --prefix) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then prefix="$2"; shift; fi; shift ;;
        --project-container=*) project_container="${1#*=}"; shift ;;
        --project-container) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then project_container="$2"; shift; fi; shift ;;
        --project-name=*) project_name="${1#*=}"; shift ;;
        --project-name) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then project_name="$2"; shift; fi; shift ;;
        --project-parent-name=*) project_parent_name="${1#*=}"; shift ;;
        --project-parent-name) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then project_parent_name="$2"; shift; fi; shift ;;
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
    echo '0.9.0'
}
printHelp() {
    title RCM Drupal Auto-Installer
    _ 'Variation '; yellow Nginx PHP-FPM; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    nginx_user=
    conf_nginx=`command -v nginx > /dev/null && command -v nginx > /dev/null && nginx -V 2>&1 | grep -o -P -- '--conf-path=\K(\S+)'`
    if [ -f "$conf_nginx" ];then
        nginx_user=`grep -o -P '^user\s+\K([^;]+)' "$conf_nginx"`
    fi
    [ -n "$nginx_user" ] && { nginx_user=" ${nginx_user},"; }
    cat << EOF
Usage: rcm-drupal-autoinstaller-nginx [options]

Options:
   --project-name *
        Set the project name. This should be in machine name format.
   --project-parent-name
        Set the project parent name. The parent is not have to installed before.
   --php-version *
        Set the version of PHP. Available values: [a], [b], or other.
        [a]: 8.2
        [b]: 8.3
   --drupal-version *
        Set the version of Drupal.
   --php-fpm-user
        Set the system user of PHP FPM. Available values:${nginx_user}`cut -d: -f1 /etc/passwd | while read line; do [ -d /home/$line ] && echo " ${line}"; done | tr $'\n' ','` or other. Default to Nginx User.
   --prefix
        Set prefix directory for project. Default to home directory of --php-fpm-user or /usr/local/share.
   --project-container
        Set the container directory for all projects. Available value: drupal-projects, drupal, or other. Default to drupal-projects.
   --auto-add-group ^
        If Nginx User cannot access PHP-FPM's Directory, auto add group of PHP-FPM User to Nginx User.

Global Options.
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.
   --root-sure
        Bypass root checking.

Environment Variables.
   DRUPAL_DB_USER_HOST
        Default to localhost
   PHP_FPM_POOL_DIRECTORY
        Default to /etc/php/[php-version]/fpm/pool.d
   PREFIX_MASTER
        Default to /usr/local/share/drupal
   PROJECTS_CONTAINER_MASTER
        Default to projects
   MARIADB_PREFIX_MASTER
        Default to /usr/local/share/mariadb
   MARIADB_USERS_CONTAINER_MASTER
        Default to users

Dependency:
   sudo
   composer
   pwgen
   curl
   rcm-nginx-setup-drupal
   rcm-mariadb-setup-project-database

Download:
   [rcm-nginx-setup-drupal](https://github.com/ijortengab/drupal-autoinstaller/blob/master/rcm/nginx/rcm-nginx-setup-drupal.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v "${line}" >/dev/null || { echo -e "\e[91m""Unable to proceed, "'`'"${line}"'`'" command not found." "\e[39m"; exit 1; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

# Functions.
validateMachineName() {
    local value="$1" _value
    local parameter="$2"
    if [[ $value = *" "* ]];then
        [ -n "$parameter" ]  && error "Variable $parameter can not contain space."
        return 1;
    fi
    _value=$(sed -E 's|[^a-zA-Z0-9]|_|g' <<< "$value" | sed -E 's|_+|_|g' )
    if [[ ! "$value" == "$_value" ]];then
        error "Variable $parameter can only contain alphanumeric and underscores."
        _ 'Suggest: '; yellow "$_value"; _.
        return 1
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
databaseCredentialDrupal() {
    local DB_USER DB_USER_PASSWORD
    if [ ! -f "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential/database" ];then
        chapter Membuat database credentials: '`'$prefix/$project_container/$project_dir/credential/database'`'.
        db_user="$project_name"
        [ -n "$project_parent_name" ] && {
            db_user=$project_parent_name
        }
        __ Memerlukan file '`'"${MARIADB_PREFIX_MASTER}/${MARIADB_USERS_CONTAINER_MASTER}/${db_user}"'`'
        fileMustExists "${MARIADB_PREFIX_MASTER}/${MARIADB_USERS_CONTAINER_MASTER}/${db_user}"
        . "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential/database"
        ____

        source="${MARIADB_PREFIX_MASTER}/${MARIADB_USERS_CONTAINER_MASTER}/${db_user}"
        target="${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential/database"
        mkdir -p "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential"
        chmod 0500 "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential"
        link_symbolic "$source" "$target"

        # Karena belum ada function link_symbolic untuk directory, maka:
        chapter Membuat symbolic link directory.
        mkdir -p "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential"
        source="${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential"
        target="${prefix}/${project_container}/${project_dir}/credential"
        __ source: '`'$source'`'
        __ target: '`'$target'`'
        if [ -d "$target" ];then
            if [ -h "$target" ];then
                _dereference=$(stat ${stat_cached} "$target" -c %N)
                source_current=$(grep -Eo "' -> '.*'$" <<< "$_dereference" | sed -E "s/' -> '(.*)'$/\1/")
                __; _, Mengecek apakah symbolic link merujuk ke '`'$source'`':
                if [[ "$source_current" == "$source" ]];then
                    _, ' 'Merujuk.; _.
                else
                    _, ' 'Tidak merujuk.; _.
                    __; red Symbolic link merujuk ke: '`'$source_current'`'.; _.
                    __ Mohon hapus manual untuk melanjutkan.
                    __; magenta rm '"'$target'"'
                    x
                fi
            else
                __; red Direktori exists: '`'$target'`'.; _.
                __ Mohon pindahkan manual untuk melanjutkan.
                __; magenta mv '"'$target'"' -t '"'$PREFIX_MASTER/$PROJECTS_CONTAINER_MASTER/${project_dir}'"'
                x
            fi
        fi

        # Sebagai referensi.
        cd "${prefix}/${project_container}/${project_dir}"
        ln -sf "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential"
        cd - >/dev/null
    fi

    # Populate.
    . "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential/database"
    db_user=$DB_USER
    db_user_password=$DB_USER_PASSWORD
}
websiteCredentialDrupal() {
    if [ -f "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential/drupal/${drupal_fqdn_localhost}" ];then
        local ACCOUNT_NAME ACCOUNT_PASS
        . "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential/drupal/${drupal_fqdn_localhost}"
        account_name=$ACCOUNT_NAME
        account_pass=$ACCOUNT_PASS
    else
        account_name=system
        account_pass=$(pwgen -s 32 -1)
        mkdir -p "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential/drupal"
        cat << EOF > "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential/drupal/${drupal_fqdn_localhost}"
ACCOUNT_NAME=$account_name
ACCOUNT_PASS=$account_pass
EOF
        chmod 0500 "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential"
        chmod 0500 "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential/drupal"
        chmod 0400 "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential/drupal/${drupal_fqdn_localhost}"
    fi
}
fileMustExists() {
    # global used:
    # global modified:
    # function used: __, success, error, x
    if [ -f "$1" ];then
        __; green File '`'$(basename "$1")'`' ditemukan.; _.
    else
        __; red File '`'$(basename "$1")'`' tidak ditemukan.; x
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

# Title.
title rcm-drupal-autoinstaller-nginx
____

# Requirement, validate, and populate value.
chapter Dump variable.
delay=.5; [ -n "$fast" ] && unset delay
[ -n "$fast" ] && isfast=' --fast' || isfast=''
DRUPAL_DB_USER_HOST=${DRUPAL_DB_USER_HOST:=localhost}
code 'DRUPAL_DB_USER_HOST="'$DRUPAL_DB_USER_HOST'"'
if [ -z "$project_name" ];then
    error "Argument --project-name required."; x
fi
code 'project_name="'$project_name'"'
if ! validateMachineName "$project_name" project_name;then x; fi
code 'project_parent_name="'$project_parent_name'"'
if [ -n "$project_parent_name" ];then
    if ! validateMachineName "$project_parent_name" project_parent_name;then x; fi
fi
code 'domain_strict="'$domain_strict'"'
if [ -z "$drupal_version" ];then
    error "Argument --drupal-version required."; x
fi
code 'drupal_version="'$drupal_version'"'
vercomp 8 "$drupal_version"
if [[ $? -lt 2 ]];then
    red Hanya mendukung Drupal versi '>=' 8.; x
fi
if [ -z "$php_version" ];then
    error "Argument --php-version required."; x
fi
code 'php_version="'$php_version'"'
project_dir="$project_name"
drupal_nginx_config_file="${project_name}__drupal"
drupal_fqdn_localhost="$project_name".drupal.localhost
drupal_db_name="${project_name}__drupal"
sites_subdir=$project_name
[ -n "$project_parent_name" ] && {
    project_dir="$project_parent_name"
    drupal_nginx_config_file="${project_parent_name}__${project_name}__drupal"
    drupal_fqdn_localhost="$project_name"."$project_parent_name".drupal.localhost
    drupal_db_name="${project_parent_name}__${project_name}__drupal"
    sites_subdir="${project_parent_name}__${project_name}"
}
sites_subdir=$(tr _ - <<< "$sites_subdir")
code 'project_dir="'$project_dir'"'
code 'drupal_nginx_config_file="'$drupal_nginx_config_file'"'
code 'drupal_fqdn_localhost="'$drupal_fqdn_localhost'"'
code 'drupal_db_name="'$drupal_db_name'"'
code 'sites_subdir="'$sites_subdir'"'
nginx_user=
conf_nginx=`command -v nginx > /dev/null && command -v nginx > /dev/null && nginx -V 2>&1 | grep -o -P -- '--conf-path=\K(\S+)'`
if [ -f "$conf_nginx" ];then
    nginx_user=`grep -o -P '^user\s+\K([^;]+)' "$conf_nginx"`
fi
code 'nginx_user="'$nginx_user'"'
if [ -z "$nginx_user" ];then
    error "Variable \$nginx_user failed to populate."; x
fi
if [ -z "$php_fpm_user" ];then
    php_fpm_user="$nginx_user"
fi
code 'php_fpm_user="'$php_fpm_user'"'
if [ -z "$prefix" ];then
    prefix=$(getent passwd "$php_fpm_user" | cut -d: -f6 )
fi
# Jika $php_fpm_user adalah nginx, maka $HOME nya adalah /nonexistent, maka
# perlu kita verifikasi lagi.
if [ ! -d "$prefix" ];then
    prefix=
fi
if [ -z "$prefix" ];then
    prefix=/usr/local/share
    project_container=drupal
fi
if [ -z "$project_container" ];then
    project_container=drupal-projects
fi
code 'prefix="'$prefix'"'
code 'project_container="'$project_container'"'
code 'auto_add_group="'$auto_add_group'"'
PHP_FPM_POOL_DIRECTORY=${PHP_FPM_POOL_DIRECTORY:=/etc/php/[php-version]/fpm/pool.d}
find='[php-version]'
replace="$php_version"
PHP_FPM_POOL_DIRECTORY="${PHP_FPM_POOL_DIRECTORY/"$find"/"$replace"}"
code 'PHP_FPM_POOL_DIRECTORY="'$PHP_FPM_POOL_DIRECTORY'"'
vercomp `stat --version | head -1 | grep -o -E '\S+$'` 8.31
if [[ $? -lt 2 ]];then
    stat_cached=' --cached=never'
else
    stat_cached=''
fi
PREFIX_MASTER=${PREFIX_MASTER:=/usr/local/share/drupal}
code 'PREFIX_MASTER="'$PREFIX_MASTER'"'
PROJECTS_CONTAINER_MASTER=${PROJECTS_CONTAINER_MASTER:=projects}
code 'PROJECTS_CONTAINER_MASTER="'$PROJECTS_CONTAINER_MASTER'"'
MARIADB_PREFIX_MASTER=${MARIADB_PREFIX_MASTER:=/usr/local/share/mariadb}
code 'MARIADB_PREFIX_MASTER="'$MARIADB_PREFIX_MASTER'"'
MARIADB_USERS_CONTAINER_MASTER=${MARIADB_USERS_CONTAINER_MASTER:=users}
code 'MARIADB_USERS_CONTAINER_MASTER="'$MARIADB_USERS_CONTAINER_MASTER'"'
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

chapter Mengecek PHP-FPM User.
code id -u '"'$php_fpm_user'"'
if id "$php_fpm_user" >/dev/null 2>&1; then
    __ User '`'$php_fpm_user'`' found.
else
    error User '`'$php_fpm_user'`' not found.; x
fi
____

source="${prefix}/${project_container}/${project_dir}/drupal"
target="${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/drupal"
chapter Memeriksa direktori '`'$target'`'
create=
if [ -d "$target" ];then
    if [ -h "$target" ];then
        code 'source="'$source'"'
        code 'target="'$target'"'
        __ Directory merupakan sebuah symbolic link.
        _dereference=$(stat ${stat_cached} "$target" -c %N)
        source_current=$(grep -Eo "' -> '.*'$" <<< "$_dereference" | sed -E "s/' -> '(.*)'$/\1/")
        __; _, Mengecek apakah symbolic link merujuk ke '`'$source'`':
        if [[ "$source_current" == "$source" ]];then
            _, ' 'Merujuk.; _.
        else
            _, ' 'Tidak merujuk.; _.
            __; red Drupal sudah terinstall di: '`'$source_current'`'.; _.
            __ Mohon ubah --project-name dan atau --project-parent-name untuk melanjutkan.
            x
        fi
    else
        if [ $(stat ${stat_cached} "$target" -c %U) == "$php_fpm_user" ];then
            __ Directory '`'"$target"'`' dimiliki oleh '`'$php_fpm_user'`'.
        else
            __; red Directory '`'"$target"'`' tidak dimiliki oleh '`'$php_fpm_user'`'.; _.
            __ Mohon ubah --project-name dan atau --project-parent-name untuk melanjutkan.
            x
        fi
    fi
else
    create=1
fi

target_master="${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}"
chapter Mengecek direktori master project '`'$target_master'`'.
isDirExists "$target_master"
____

if [ -n "$notfound" ];then
    chapter Membuat direktori master project.
    code mkdir -p '"'$target_master'"'
    code chown $php_fpm_user:$php_fpm_user '"'$target_master'"'
    mkdir -p "$target_master"
    chown $php_fpm_user:$php_fpm_user "$target_master"
    dirMustExists "$target_master"
    ____
fi

target_project_container="${prefix}/${project_container}"
chapter Mengecek direktori project container '`'$target_project_container'`'.
isDirExists "$target_project_container"
____

if [ -n "$notfound" ];then
    chapter Membuat direktori project container.
    code mkdir -p '"'$target_project_container'"'
    code chown $php_fpm_user:$php_fpm_user '"'$target_project_container'"'
    mkdir -p "$target_project_container"
    chown $php_fpm_user:$php_fpm_user "$target_project_container"
    dirMustExists "$target_project_container"
    ____
fi

target="${prefix}/${project_container}/${project_dir}"
chapter Mengecek direktori project '`'$target'`'.
isDirExists "$target"
____

if [ -n "$notfound" ];then
    chapter Membuat direktori project.
    code alias mkdir='"'sudo -u $php_fpm_user mkdir'"'
    code mkdir -p "$target"
    code unalias mkdir
    sudo -u "$php_fpm_user" mkdir -p "$target"
    dirMustExists "$target"
    ____
fi

target_web_root="${prefix}/${project_container}/${project_dir}/drupal/web"
chapter Mengecek direktori project web root '`'$target_web_root'`'.
isDirExists "$target_web_root"
____

if [ -n "$notfound" ];then
    chapter Membuat direktori project web root.
    code alias mkdir='"'sudo -u $php_fpm_user mkdir'"'
    code mkdir -p "$target_web_root"
    code unalias mkdir
    sudo -u "$php_fpm_user" mkdir -p "$target_web_root"
    dirMustExists "$target_web_root"
    ____
fi

if [ -n "$create" ];then
    source="${prefix}/${project_container}/${project_dir}/drupal"
    target="${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/drupal"
    link_symbolic "$source" "$target"
fi

is_access=
chapter Memastikan Nginx User dapat mengakses Direktori Project.
code sudo -u '"'$nginx_user'"' bash -c '"'cd "$target_web_root"'"'
if sudo -u "$nginx_user" bash -c "cd ${target_web_root}";then
    __ Direktori dapat diakses.
    is_access=1
else
    __ Direktori tidak dapat diakses.
fi
if [[ -z "$is_access" ]];then
    __ Mengecek flag --auto-add-group sebagai salah satu solusi.
    if [[ -n "$auto_add_group" ]];then
        __ Flag --auto-add-group ditemukan.
        __ Memberi akses Group PHP-FPM User kepada Nginx User.
        code usermod -a -G '"'"$php_fpm_user"'"' '"'"$nginx_user"'"'
        usermod -a -G "$php_fpm_user" "$nginx_user"
        __ Memberi akses Permission kepada direktori.
        path="${prefix}/${project_container}/${project_dir}/drupal/web"
        until [[ "$path" == / || "$path" == /home ]];do
            __; magenta chmod g+rx "$path"; _.
            chmod g+rx "$path"
            sudo -u "www-data" bash -c "cd '$path'" && break
            path=$(dirname "$path")
            sleep .1
        done
    else
        __ Flag --auto-add-group tidak ditemukan.
    fi
fi
if [[ -z "$is_access" ]];then
    if sudo -u "$nginx_user" bash -c "cd ${prefix}/${project_container}/${project_dir}/drupal/web" 2>/dev/null;then
        success Direktori dapat diakses.
    else
        error Direktori tidak dapat diakses oleh Nginx User '('"$nginx_user"')'.; x
    fi
fi
____

chapter Prepare arguments.
____; socket_filename=$(INDENT+="    " rcm-php-fpm-setup-pool $isfast --root-sure --php-version="$php_version" --php-fpm-user="$php_fpm_user" get listen)
if [ -z "$socket_filename" ];then
    __; red Socket Filename of PHP-FPM not found.; x
fi
code socket_filename="$socket_filename"
root="$prefix/${project_container}/$project_dir/drupal/web"
code root="$root"
filename="$drupal_nginx_config_file"
code filename="$filename"
server_name="$drupal_fqdn_localhost"
code server_name="$server_name"
____

INDENT+="    " \
rcm-nginx-setup-drupal \
    --root-sure \
    --root="$root" \
    --filename="$filename" \
    --server-name="$server_name" \
    --fastcgi-pass="unix:${socket_filename}" \
    ; [ ! $? -eq 0 ] && x

chapter Mengecek subdomain '`'$drupal_fqdn_localhost'`'.
notfound=
string="$drupal_fqdn_localhost"
string_quoted=$(sed "s/\./\\\./g" <<< "$string")
if grep -q -E "^\s*127\.0\.0\.1\s+${string_quoted}" /etc/hosts;then
    __ Subdomain terdapat pada local DNS resolver '`'/etc/hosts'`'.
else
    __ Subdomain tidak terdapat pada local DNS resolver '`'/etc/hosts'`'.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    chapter Menambahkan subdomain '`'$drupal_fqdn_localhost'`'.
    echo "127.0.0.1"$'\t'"${drupal_fqdn_localhost}" >> /etc/hosts
    if grep -q -E "^\s*127\.0\.0\.1\s+${string_quoted}" /etc/hosts;then
        __; green Subdomain terdapat pada local DNS resolver '`'/etc/hosts'`'.; _.
    else
        __; red Subdomain tidak terdapat pada local DNS resolver '`'/etc/hosts'`'.; x
    fi
    ____
fi

chapter Memastikan informasi PHP-FPM User.
__ Membuat file "${root}/.well-known/__getuser.php"
mkdir -p "${root}/.well-known"
cat << 'EOF' > "${root}/.well-known/__getuser.php"
<?php
echo $_SERVER['USER'];
EOF
__ Eksekusi file script.
__; magenta curl http://127.0.0.1/.well-known/__getuser.php -H "Host: ${drupal_fqdn_localhost}"; _.
_php_fpm_user=$(curl -Ss http://127.0.0.1/.well-known/__getuser.php -H "Host: ${drupal_fqdn_localhost}")
__; magenta _php_fpm_user="$_php_fpm_user"; _.
if [[ ! "$_php_fpm_user" == "$php_fpm_user" ]];then
    error PHP-FPM User berbeda.; x
fi
__ Menghapus file "${root}/.well-known/__getuser.php"
rm "${root}/.well-known/__getuser.php"
rmdir "${root}/.well-known" --ignore-fail-on-non-empty
rmdir "$prefix/${project_container}/$project_dir/drupal/web" --ignore-fail-on-non-empty
____

chapter Mengecek file '`'composer.json'`' untuk project '`'drupal/recommended-project'`'
notfound=
if [ -f "$prefix"/"$project_container"/$project_dir/drupal/composer.json ];then
    __ File '`'composer.json'`' ditemukan.
else
    __ File '`'composer.json'`' tidak ditemukan.
    notfound=1
fi
# User www-data memiliki $HOME di /var/www,
# Kita perlu membersihkan direktori /var/www dari autocreate directory .cache dan .config
# sehingga kita ubah $HOME menjadi di /tmp
env=
if [[ "$nginx_user" == "$php_fpm_user" ]];then
    env='HOME=/tmp -E'
fi
____

if [ -n "$notfound" ];then
    chapter Mendownload composer.json untuk project '`'drupal/recommended-project'`'.
    cd "$prefix"/"$project_container"/$project_dir
    # Jika version hanya angka 9 atau 10, maka ubah menjadi ^9 atau ^10.
    if [[ "$drupal_version" =~ ^[0-9]+$ ]];then
        _drupal_version="$drupal_version"
        drupal_version="^${drupal_version}"
    fi
    # https://www.drupal.org/docs/develop/using-composer/manage-dependencies
    # Code dibawah ini tidak mendetect environment variable terutama http_proxy,
    # sehingga composer gagal mendownload.
    # sudo -u $user_nginx HOME='/tmp' -s composer create-project --no-install drupal/recommended-project drupal $drupal_version
    # Alternative menggunakan code dibawah ini.
    # Credit: https://stackoverflow.com/a/8633575
    code sudo -u $php_fpm_user $env bash -c '"'composer create-project --no-install drupal/recommended-project:${drupal_version} drupal'"'
    sudo -u $php_fpm_user $env bash -c "composer create-project --no-install drupal/recommended-project:${drupal_version} drupal"
    drupal_version="$_drupal_version"
    cd - >/dev/null
    fileMustExists "${prefix}/${project_container}/${project_dir}/drupal/composer.json"
    ____
fi

chapter Mengecek dependencies menggunakan Composer.
notfound=
cd "${prefix}/${project_container}/${project_dir}/drupal"
msg=$(sudo -u $php_fpm_user $env -s composer show 2>&1)
if ! grep -q '^No dependencies installed.' <<< "$msg";then
    __ Dependencies installed.
else
    __ Dependencies not installed.
    notfound=1
fi
cd - >/dev/null
____

if [ -n "$notfound" ];then
    chapter Mendownload dependencies menggunakan Composer.
    cd "${prefix}/${project_container}/${project_dir}/drupal"
    code sudo -u $php_fpm_user $env bash -c '"'composer -v install'"'
    sudo -u $php_fpm_user $env bash -c "composer -v install"
    cd - >/dev/null
    ____
fi

chapter Mengecek drush.
notfound=
cd "${prefix}/${project_container}/${project_dir}/drupal"
if sudo -u $php_fpm_user $env composer show | grep -q '^drush/drush';then
    __ Drush exists.
else
    __ Drush is not exists.
    notfound=1
fi
cd - >/dev/null
____

if [ -n "$notfound" ];then
    chapter Memasang '`'Drush'`' menggunakan Composer.
    cd "${prefix}/${project_container}/${project_dir}/drupal"
    # sudo -u $php_fpm_user HOME='/tmp' -s composer -v require drush/drush
    code sudo -u $php_fpm_user $env bash -c '"'composer -v require drush/drush'"'
    sudo -u $php_fpm_user $env bash -c "composer -v require drush/drush"
    if [ -f "${prefix}/${project_container}/${project_dir}/drupal/vendor/bin/drush" ];then
        __; green Binary Drush is exists.
    else
        __; red Binary Drush is not exists.; x
    fi
    cd - >/dev/null
    ____
fi

PATH="${prefix}/${project_container}/${project_dir}/drupal/vendor/bin":$PATH

chapter Mengecek domain-strict.
if [ -n "$domain_strict" ];then
    __ Instalasi Drupal tidak menggunakan '`'default'`'.
else
    __ Instalasi Drupal menggunakan '`'default'`'.
fi
____

chapter Mengecek apakah Drupal sudah terinstall sebagai singlesite '`'default'`'.
cd "${prefix}/${project_container}/${project_dir}/drupal"
default_installed=
if drush status --field=db-status | grep -q '^Connected$';then
    __ Drupal site default installed.
    default_installed=1
else
    __ Drupal site default not installed.
fi
cd - >/dev/null
____

install_type=singlesite
chapter Mengecek Drupal multisite
if [ -n "$project_parent_name" ];then
    __ Project parent didefinisikan. Menggunakan Drupal multisite.
    if [ -f "${prefix}/${project_container}/${project_dir}/drupal/web/sites/sites.php" ];then
        __ Files '`'sites.php'`' ditemukan.
    else
        __ Files '`'sites.php'`' belum ditemukan.
    fi
    install_type=multisite
else
    __ Project parent tidak didefinisikan.
fi
if [[ -n "$domain_strict"  && -z "$default_installed" ]];then
    __ Domain strict didefinisikan. Menggunakan Drupal multisite.
    install_type=multisite
else
    __ Domain strict tidak didefinisikan.
fi
____

# allsite=("${domain[@]}")
# allsite+=("${drupal_fqdn_localhost}")
allsite=("${drupal_fqdn_localhost}")
multisite_installed=
for eachsite in "${allsite[@]}" ;do
    chapter Mengecek apakah Drupal sudah terinstall sebagai multisite '`'$eachsite'`'.
    if [[ "sites/${sites_subdir}" == $(drush status --uri=$eachsite --field=site) ]];then
        __ Site direktori dari domain '`'$eachsite'`' sesuai, yakni: '`'sites/$sites_subdir'`'.
        if drush status --uri=$eachsite --field=db-status | grep -q '^Connected$';then
            __ Drupal site '`'$eachsite'`' installed.
            multisite_installed=1
        else
            __ Drupal site '`'$eachsite'`' not installed yet.
        fi
    else
        __ Site direktori dari domain '`'$eachsite'`' tidak sesuai.
    fi
    ____
done

chapter Dump variable installed.
code install_type="$install_type"
code domain_strict="$domain_strict"
code default_installed="$default_installed"
code multisite_installed="$multisite_installed"
____

if [[ "$install_type" == singlesite && -z "$domain_strict" && -z "$default_installed" && -n "$multisite_installed" ]];then
    chapter Drupal multisite sudah terinstall.
    __ Sebelumnya sudah di-install dengan option --domain-strict.
    __ Agar proses dapat dilanjutkan, perlu kerja manual dengan memperhatikan sbb:
    __ - Move file '`'settings.php'`' dari '`'sites/'<'sites_subdir'>''`' menjadi '`'sites/default'`'.
    __ - Move file-file script PHP yang di-include oleh '`'settings.php'`'.
    __ - Mengubah informasi public files pada config. Biasanya berada di '`'sites/'<'sites_subdir'>'/files'`'.
    __ - Menghapus informasi site di '`'sites/sites.php'`'.
    __; red Process terminated; x
fi

if [[ -n "$domain_strict" && -n "$default_installed" ]];then
    chapter Drupal singlesite default sudah terinstall.
    __ Option --domain-strict tidak bisa digunakan.
    __ Agar proses dapat dilanjutkan, perlu kerja manual dengan memperhatikan sbb:
    __ - Move file '`'settings.php'`' dari '`'sites/default'`' menjadi '`'sites/'<'sites_subdir'>''`'.
    __ - Move file-file script PHP yang di-include oleh '`'settings.php'`'.
    __ - Mengubah informasi public files pada config. Biasanya berada di '`'sites/default/files'`'.
    __ - Menghapus informasi site di '`'sites/sites.php'`'.
    __; red Process terminated; x
fi

INDENT+="    " \
rcm-mariadb-setup-project-database $isfast --root-sure \
    --project-name="$project_name" \
    --project-parent-name="$project_parent_name" \
    --db-suffix-name="drupal" \
    ; [ ! $? -eq 0 ] && x

databaseCredentialDrupal

chapter Mengecek website credentials: '`'$prefix/$project_container/$project_dir/credential/drupal/$drupal_fqdn_localhost'`'.
websiteCredentialDrupal
if [[ -z "$account_name" || -z "$account_pass" ]];then
    __; red Informasi credentials tidak lengkap: '`'$prefix/$project_container/$project_dir/credential/drupal/$drupal_fqdn_localhost'`'.; x
else
    code account_name="$account_name"
    code account_pass="$account_pass"
fi
____

if [[ $install_type == 'singlesite' && -z "$default_installed" ]];then
    chapter Install Drupal site default.
    code drush site:install --yes \
        --account-name="$account_name" --account-pass="$account_pass" \
        --db-url="mysql://${db_user}:${db_user_password}@${DRUPAL_DB_USER_HOST}/${drupal_db_name}"
    sudo -u $php_fpm_user PATH="${prefix}/${project_container}/${project_dir}/drupal/vendor/bin":$PATH $env -s \
        drush site:install --yes \
            --account-name="$account_name" --account-pass="$account_pass" \
            --db-url="mysql://${db_user}:${db_user_password}@${DRUPAL_DB_USER_HOST}/${drupal_db_name}"
    if drush status --field=db-status | grep -q '^Connected$';then
        __; green Drupal site default installed.
    else
        __; red Drupal site default not installed.; x
    fi
    ____
fi

if [[ $install_type == 'multisite' && -z "$multisite_installed" ]];then
    chapter Install Drupal multisite.
    code drush site:install --yes \
        --account-name="$account_name" --account-pass="$account_pass" \
        --db-url="mysql://${db_user}:${db_user_password}@${DRUPAL_DB_USER_HOST}/${drupal_db_name}" \
        --sites-subdir=${sites_subdir}
    sudo -u $php_fpm_user PATH="${prefix}/${project_container}/${project_dir}/drupal/vendor/bin":$PATH $env -s \
        drush site:install --yes \
            --account-name="$account_name" --account-pass="$account_pass" \
            --db-url="mysql://${db_user}:${db_user_password}@${DRUPAL_DB_USER_HOST}/${drupal_db_name}" \
            --sites-subdir=${sites_subdir}
    if [ -f "${prefix}/${project_container}/${project_dir}/drupal/web/sites/sites.php" ];then
        __; green Files '`'sites.php'`' ditemukan.; _.
    else
        __; red Files '`'sites.php'`' tidak ditemukan.; x
    fi
    php=$(cat <<'EOF'
$args = $_SERVER['argv'];
array_shift($args);
$file = $args[0];
array_shift($args);
$sites_subdir = $args[0];
array_shift($args);
include($file);
if (!isset($sites)) {
    $sites = [];
}
while ($site = array_shift($args)) {
    $sites[$site] = $sites_subdir;
}
$content = '$sites = '.var_export($sites, true).';'.PHP_EOL;
$content = <<< EOF
<?php
$content
EOF;
file_put_contents($file, $content);
EOF
)
    sudo -u $php_fpm_user \
        php -r "$php" \
            "${prefix}/${project_container}/${project_dir}/drupal/web/sites/sites.php" \
            "$sites_subdir" \
            "${allsite[@]}"
    error=
    for eachsite in "${allsite[@]}" ;do
        if [[ "sites/${sites_subdir}" == $(drush status --uri=$eachsite --field=site) ]];then
            __; green Site direktori dari domain '`'$eachsite'`' sesuai, yakni: '`'sites/$sites_subdir'`'.; _.
        else
            __; red Site direktori dari domain '`'$eachsite'`' tidak sesuai.
            error=1
        fi
        if drush status --uri=$eachsite --field=db-status | grep -q '^Connected$';then
            __; green Drupal site '`'$eachsite'`' installed.; _.
        else
            __; red Drupal site '`'$eachsite'`' not installed yet.
            error=1
        fi
    done
    if [ -n "$error" ];then
        x
    fi
    ____
fi

chapter Mengecek HTTP Response Code.
code curl http://127.0.0.1 -H '"'Host: ${drupal_fqdn_localhost}'"'
code=$(curl -L \
    -o /dev/null -s -w "%{http_code}\n" \
    http://127.0.0.1 -H "Host: ${drupal_fqdn_localhost}")
[[ $code =~ ^[2,3] ]] && {
    __ HTTP Response code '`'$code'`' '('Required')'.
} || {
    __; red Terjadi kesalahan. HTTP Response code '`'$code'`'.; x
}
code curl http://${drupal_fqdn_localhost}
code=$(curl -L \
    -o /dev/null -s -w "%{http_code}\n" \
    http://127.0.0.1 -H "Host: ${drupal_fqdn_localhost}")
__ HTTP Response code '`'$code'`'.
____

exit 0

# parse-options.sh \
# --without-end-options-double-dash \
# --compact \
# --clean \
# --no-hash-bang \
# --no-original-arguments \
# --no-error-invalid-options \
# --no-error-require-arguments << EOF
# FLAG=(
# --fast
# --version
# --help
# --root-sure
# --domain-strict
# --auto-add-group
# )
# VALUE=(
# --drupal-version
# --php-version
# --project-name
# --project-parent-name
# --php-fpm-user
# --prefix
# --project-container
# )
# FLAG_VALUE=(
# )
# EOF
