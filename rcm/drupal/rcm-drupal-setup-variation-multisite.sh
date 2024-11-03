#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then domain="$2"; shift; fi; shift ;;
        --domain-strict) domain_strict=1; shift ;;
        --existing-project-name=*) project_parent_name="${1#*=}"; shift ;;
        --existing-project-name) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then project_parent_name="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --root-sure) root_sure=1; shift ;;
        --sub-project-name=*) project_name="${1#*=}"; shift ;;
        --sub-project-name) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then project_name="$2"; shift; fi; shift ;;
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
    echo '0.11.9'
}
printHelp() {
    title RCM Drupal Setup
    _ 'Variation '; yellow MultiSite; _, . Multi Site in one codebase. ; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-drupal-setup-variation-multisite [options]

Options:
   --existing-project-name *
        Select the existing project to use the same codebase. Value available from command: ls-drupal().
   --sub-project-name *
        Set the sub project name as identifier. This should be in machine name format.
   --domain
        Set the domain.

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
   PREFIX_MASTER
        Default to /usr/local/share/drupal
   PROJECTS_CONTAINER_MASTER
        Default to projects

Dependency:
   rcm-php-setup-adjust-cli-version
   rcm-wsl-setup-lemp-stack
   rcm-drupal-autoinstaller-nginx:`printVersion`
   rcm-drupal-setup-wrapper-nginx-setup-drupal:`printVersion`
   rcm-drupal-setup-drush-alias:`printVersion`
   rcm-drupal-setup-internal-command-cd-drupal:`printVersion`
   rcm-drupal-setup-internal-command-ls-drupal:`printVersion`
   rcm-drupal-setup-dump-variables:`printVersion`
   rcm-php-fpm-setup-project-config
   rcm-drupal-wrapper-certbot-deploy-nginx:`printVersion`
   rcm-dig-watch-domain-exists

Download:
   [rcm-drupal-autoinstaller-nginx](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-autoinstaller-nginx.sh)
   [rcm-drupal-setup-wrapper-nginx-setup-drupal](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-wrapper-nginx-setup-drupal.sh)
   [rcm-drupal-setup-drush-alias](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-drush-alias.sh)
   [rcm-drupal-setup-internal-command-cd-drupal](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-internal-command-cd-drupal.sh)
   [rcm-drupal-setup-internal-command-ls-drupal](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-internal-command-ls-drupal.sh)
   [rcm-drupal-setup-dump-variables](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-dump-variables.sh)
   [rcm-drupal-wrapper-certbot-deploy-nginx](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-wrapper-certbot-deploy-nginx.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-drupal-setup-variation-multisite
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

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { echo -e "\e[91m""Unable to proceed, "'`'"${line}"'`'" command not found." "\e[39m"; exit 1; }
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
databaseCredentialDrupal() {
    if [ -f "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir_basename}/credential/database" ];then
        local DB_USER DB_USER_PASSWORD
        # Populate.
        . "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir_basename}/credential/database"
        db_user=$DB_USER
        db_user_password=$DB_USER_PASSWORD
    fi
}
websiteCredentialDrupal() {
    if [ -f "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir_basename}/credential/drupal/${drupal_fqdn_localhost}" ];then
        local ACCOUNT_NAME ACCOUNT_PASS
        . "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir_basename}/credential/drupal/${drupal_fqdn_localhost}"
        account_name=$ACCOUNT_NAME
        account_pass=$ACCOUNT_PASS
    else
        account_name=system
        account_pass=$(pwgen -s 32 -1)
        mkdir -p "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir_basename}/credential/drupal"
        cat << EOF > "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir_basename}/credential/drupal/${drupal_fqdn_localhost}"
ACCOUNT_NAME=$account_name
ACCOUNT_PASS=$account_pass
EOF
        chmod 0500 "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir_basename}/credential"
        chmod 0500 "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir_basename}/credential/drupal"
        chmod 0400 "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir_basename}/credential/drupal/${drupal_fqdn_localhost}"
    fi
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

# Requirement, validate, and populate value.
chapter Dump variable.
delay=.5; [ -n "$fast" ] && unset delay
[ -n "$fast" ] && isfast=' --fast' || isfast=''
# Random value, berapapun gak ngaruh, asal diatas angka 7.
drupal_version=8
code 'drupal_version="'$drupal_version'"'
# Random value, berapapun gak ngaruh.
auto_add_group=1
[ -n "$auto_add_group" ] && is_auto_add_group=' --auto-add-group' || is_auto_add_group=''
PREFIX_MASTER=${PREFIX_MASTER:=/usr/local/share/drupal}
code 'PREFIX_MASTER="'$PREFIX_MASTER'"'
PROJECTS_CONTAINER_MASTER=${PROJECTS_CONTAINER_MASTER:=projects}
code 'PROJECTS_CONTAINER_MASTER="'$PROJECTS_CONTAINER_MASTER'"'
if [ -z "$project_parent_name" ];then
    error "Argument --existing-project-name required."; x
fi
code 'project_parent_name="'$project_parent_name'"'
if [ -z "$project_name" ];then
    error "Argument --sub-project-name required."; x
fi
code 'project_name="'$project_name'"'
code 'domain="'$domain'"'
project_dir_basename="$project_parent_name"
code 'project_dir_basename="'$project_dir_basename'"'
target="${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir_basename}/drupal"
code 'target="'$target'"'
if [ -d "$target" ];then
    if [ -h "$target" ];then
            _readlink=$(readlink "$target")
            if [[ "$_readlink" =~ ^[^/\.] ]];then
                local target_parent=$(dirname "$target")
                local _dereference="${target_parent}/${_readlink}"
            elif [[ "$_readlink" =~ ^[\.] ]];then
                local target_parent=$(dirname "$target")
                local _dereference="${target_parent}/${_readlink}"
                _dereference=$(realpath -s "$_dereference")
            else
                _dereference="$_readlink"
            fi
            source="$_dereference"
    else
        # e todo, mungkin ada kasus seperti ini dan itu gpp.
        error Target merupakan regular direktori.;x
    fi
elif [ -f "$target" ];then
    if [ -h "$target" ];then
        error Target merupakan symbolic link mengarah ke regular file.;x
    else
        error Target merupakan regular file.;x
    fi
else
    error Target tidak diketahui.;x
fi
code 'source="'$source'"'
project_dir=$(dirname "$source")
code 'project_dir="'$project_dir'"'
path="${source}/composer.json"
[ -f "$path" ] || fileMustExists "$path"
php_fpm_user=$(stat -c "%U" "$path")
code 'php_fpm_user="'$php_fpm_user'"'
is_wsl=
if [ -f /proc/sys/kernel/osrelease ];then
    read osrelease </proc/sys/kernel/osrelease
    if [[ "$osrelease" =~ microsoft || "$osrelease" =~ Microsoft ]];then
        is_wsl=1
    fi
fi
code 'is_wsl="'$is_wsl'"'
____

if [ -n "$domain" ];then
    INDENT+="    " \
    rcm-dig-watch-domain-exists $isfast --root-sure \
        --domain="$domain" \
        --waiting-time="60" \
        ; [ ! $? -eq 0 ] && x
fi

chapter Prepare arguments.
web_root="${source}/web"
code web_root="$web_root"
drupal_fqdn_localhost="$project_parent_name".drupal.localhost
code drupal_fqdn_localhost="$drupal_fqdn_localhost"
____

chapter Mencari informasi PHP-FPM Version yang digunakan oleh Drupal.
__ Membuat file "${web_root}/.well-known/__getversion.php"
mkdir -p "${web_root}/.well-known"
cat << 'EOF' > "${web_root}/.well-known/__getversion.php"
<?php
echo PHP_VERSION;
EOF
__ Eksekusi file script.
__; magenta curl http://127.0.0.1/.well-known/__getversion.php -H '"'"Host: ${drupal_fqdn_localhost}"'"'; _.
php_version=$(curl -Ss http://127.0.0.1/.well-known/__getversion.php -H "Host: ${drupal_fqdn_localhost}")
__; magenta php_version="$php_version"; _.
if [ -z "$php_version" ];then
    error PHP-FPM version tidak ditemukan; x
fi
__ Menghapus file "${web_root}/.well-known/__getversion.php"
rm "${web_root}/.well-known/__getversion.php"
rmdir "${web_root}/.well-known" --ignore-fail-on-non-empty
____

chapter Perbaikan variable '`'php_version'`'.
__; magenta php_version="$php_version"; _.
major=$(sed -E 's,^([0-9]+)\.([0-9]+)\.([0-9]+)$,\1,' <<< "$php_version")
minor=$(sed -E 's,^([0-9]+)\.([0-9]+)\.([0-9]+)$,\2,' <<< "$php_version")
php_version="${major}.${minor}"
__; magenta php_version="$php_version"; _.
____

INDENT+="    " \
rcm-php-setup-adjust-cli-version $isfast --root-sure \
    --php-version="$php_version" \
    ; [ ! $? -eq 0 ] && x

if [ -n "$is_wsl" ];then
    INDENT+="    " \
    rcm-wsl-setup-lemp-stack $isfast --root-sure \
        --php-version="$php_version" \
        ; [ ! $? -eq 0 ] && x
fi

INDENT+="    " \
rcm-php-fpm-setup-project-config $isfast --root-sure \
    --php-version="$php_version" \
    --php-fpm-user="$php_fpm_user" \
    --project-name="$project_name" \
    --project-parent-name="$project_parent_name" \
    --config-suffix-name="drupal" \
    ; [ ! $? -eq 0 ] && x

INDENT+="    " \
rcm-drupal-autoinstaller-nginx $isfast --root-sure \
    $is_auto_add_group \
    --domain="$domain" \
    --drupal-version="$drupal_version" \
    --php-version="$php_version" \
    --php-fpm-user="$php_fpm_user" \
    --project-dir="$project_dir" \
    --project-name="$project_name" \
    --project-parent-name="$project_parent_name" \
    ; [ ! $? -eq 0 ] && x

if [ -n "$domain" ];then
    INDENT+="    " \
    rcm-drupal-setup-wrapper-nginx-setup-drupal $isfast --root-sure \
        --php-version="$php_version" \
        --project-name="$project_name" \
        --project-parent-name="$project_parent_name" \
        --domain="$domain" \
        --php-fpm-user="$php_fpm_user" \
        --project-dir="$project_dir" \
        && INDENT+="    " \
    rcm-drupal-setup-wrapper-nginx-setup-drupal $isfast --root-sure \
        --php-version="$php_version" \
        --project-name="$project_name" \
        --project-parent-name="$project_parent_name" \
        --subdomain="$domain" \
        --domain="localhost" \
        --php-fpm-user="$php_fpm_user" \
        --project-dir="$project_dir" \
        ; [ ! $? -eq 0 ] && x

    chapter Mengecek '$PATH'.
    code PATH="$PATH"
    if grep -q '/snap/bin' <<< "$PATH";then
      __ '$PATH' sudah lengkap.
    else
      __ '$PATH' belum lengkap.
      __ Memperbaiki '$PATH'
      PATH=/snap/bin:$PATH
        if grep -q '/snap/bin' <<< "$PATH";then
            __; green '$PATH' sudah lengkap.; _.
            __; magenta PATH="$PATH"; _.
        else
            __; red '$PATH' belum lengkap.; x
        fi
    fi
    ____

    INDENT+="    " \
    PATH=$PATH \
    rcm-certbot-deploy-nginx $isfast --root-sure \
        --domain="${domain}" \
        ; [ ! $? -eq 0 ] && x
fi

INDENT+="    " \
rcm-drupal-setup-drush-alias $isfast --root-sure \
    --project-name="$project_name" \
    --project-parent-name="$project_parent_name" \
    --domain="$domain" \
    && INDENT+="    " \
rcm-drupal-setup-internal-command-cd-drupal $isfast --root-sure \
    && INDENT+="    " \
rcm-drupal-setup-internal-command-ls-drupal $isfast --root-sure \
    && INDENT+="    " \
rcm-drupal-setup-dump-variables $isfast --root-sure \
    --project-name="$project_name" \
    --project-parent-name="$project_parent_name" \
    --domain="$domain" \
    ; [ ! $? -eq 0 ] && x

chapter Finish
____

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
# --domain-strict
# )
# VALUE=(
# --domain
# )
# MULTIVALUE=(
# )
# FLAG_VALUE=(
# )
# CSV=(
    # 'long:--existing-project-name,parameter:project_parent_name,type:value'
    # 'long:--sub-project-name,parameter:project_name,type:value'
# )
# EOF
# clear