#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --existing-project-name=*) project_parent_name="${1#*=}"; shift ;;
        --existing-project-name) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then project_parent_name="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --sub-project-name=*) project_name="${1#*=}"; shift ;;
        --sub-project-name) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then project_name="$2"; shift; fi; shift ;;
        --url=*) url="${1#*=}"; shift ;;
        --url) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url="$2"; shift; fi; shift ;;
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
e() { echo -n "$INDENT" >&2; echo -n "$@" >&2; }
_() { echo -n "$INDENT" >&2; echo -n "#"' ' >&2; [ -n "$1" ] && echo -n "$@" >&2; }
_,() { echo -n "$@" >&2; }
_.() { echo >&2; }
__() { echo -n "$INDENT" >&2; echo -n "# ${RCM_INDENT}" >&2; [ -n "$1" ] && echo "$@" >&2; }
____() { echo >&2; [ -n "$RCM_DELAY" ] && sleep "$RCM_DELAY"; }

# Define variables and constants.
RCM_DELAY=${RCM_DELAY:=.5}; [ -n "$fast" ] && unset RCM_DELAY
RCM_INDENT='    '; [ "$(tput cols)" -le 80 ] && RCM_INDENT='  '

# Functions.
printVersion() {
    echo '0.11.25'
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
        Set the sub project name as identifier.
        Allowed characters are a-z, 0-9, and underscore (_).
   --url
        Add Drupal public domain. The value can be domain or URL.
        Drupal automatically has address at http://<subproject>.<project>.drupal.localhost/.
        Example: \`example.org\`, \`example.org/path/to/drupal/\`, or \`https://sub.example.org:8080/\`.

Global Options.
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.

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
   rcm-drupal-setup-dump-variables:`printVersion`
   rcm-php-fpm-setup-project-config
   rcm-dig-watch-domain-exists
   rcm-certbot-deploy-nginx

Download:
   [rcm-drupal-autoinstaller-nginx](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-autoinstaller-nginx.sh)
   [rcm-drupal-setup-wrapper-nginx-setup-drupal](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-wrapper-nginx-setup-drupal.sh)
   [rcm-drupal-setup-drush-alias](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-drush-alias.sh)
   [rcm-drupal-setup-dump-variables](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-dump-variables.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-drupal-setup-variation-multisite
____

[ "$EUID" -ne 0 ] && { error This script needs to be run with superuser privileges.; x; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'`cut -d: -f1 <<< "${line}"`'`'.; x; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

# Functions.
Rcm_parse_url() {
    # Reset
    PHP_URL_SCHEME=
    PHP_URL_HOST=
    PHP_URL_PORT=
    PHP_URL_USER=
    PHP_URL_PASS=
    PHP_URL_PATH=
    PHP_URL_QUERY=
    PHP_URL_FRAGMENT=
    PHP_URL_SCHEME="$(echo "$1" | grep :// | sed -e's,^\(.*\)://.*,\1,g')"
    _PHP_URL_SCHEME_SLASH="${PHP_URL_SCHEME}://"
    _PHP_URL_SCHEME_REVERSE="$(echo ${1/${_PHP_URL_SCHEME_SLASH}/})"
    if grep -q '#' <<< "$_PHP_URL_SCHEME_REVERSE";then
        PHP_URL_FRAGMENT=$(echo $_PHP_URL_SCHEME_REVERSE | cut -d# -f2)
        _PHP_URL_SCHEME_REVERSE=$(echo $_PHP_URL_SCHEME_REVERSE | cut -d# -f1)
    fi
    if grep -q '\?' <<< "$_PHP_URL_SCHEME_REVERSE";then
        PHP_URL_QUERY=$(echo $_PHP_URL_SCHEME_REVERSE | cut -d? -f2)
        _PHP_URL_SCHEME_REVERSE=$(echo $_PHP_URL_SCHEME_REVERSE | cut -d? -f1)
    fi
    _PHP_URL_USER_PASS="$(echo $_PHP_URL_SCHEME_REVERSE | grep @ | cut -d@ -f1)"
    PHP_URL_PASS=`echo $_PHP_URL_USER_PASS | grep : | cut -d: -f2`
    if [ -n "$PHP_URL_PASS" ]; then
        PHP_URL_USER=`echo $_PHP_URL_USER_PASS | grep : | cut -d: -f1`
    else
        PHP_URL_USER=$_PHP_URL_USER_PASS
    fi
    _PHP_URL_HOST_PORT="$(echo ${_PHP_URL_SCHEME_REVERSE/$_PHP_URL_USER_PASS@/} | cut -d/ -f1)"
    PHP_URL_HOST="$(echo $_PHP_URL_HOST_PORT | sed -e 's,:.*,,g')"
    if grep -q -E ':[0-9]+$' <<< "$_PHP_URL_HOST_PORT";then
        PHP_URL_PORT="$(echo $_PHP_URL_HOST_PORT | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"
    fi
    _PHP_URL_HOST_PORT_LENGTH=${#_PHP_URL_HOST_PORT}
    _LENGTH="$_PHP_URL_HOST_PORT_LENGTH"
    if [ -n "$_PHP_URL_USER_PASS" ];then
        _PHP_URL_USER_PASS_LENGTH=${#_PHP_URL_USER_PASS}
        _LENGTH=$((_LENGTH + 1 + _PHP_URL_USER_PASS_LENGTH))
    fi
    PHP_URL_PATH="${_PHP_URL_SCHEME_REVERSE:$_LENGTH}"

    # Debug
    # e '"$PHP_URL_SCHEME"' "$PHP_URL_SCHEME"; _.
    # e '"$PHP_URL_HOST"' "$PHP_URL_HOST"; _.
    # e '"$PHP_URL_PORT"' "$PHP_URL_PORT"; _.
    # e '"$PHP_URL_USER"' "$PHP_URL_USER"; _.
    # e '"$PHP_URL_PASS"' "$PHP_URL_PASS"; _.
    # e '"$PHP_URL_PATH"' "$PHP_URL_PATH"; _.
    # e '"$PHP_URL_QUERY"' "$PHP_URL_QUERY"; _.
    # e '"$PHP_URL_FRAGMENT"' "$PHP_URL_FRAGMENT"; _.
}
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

# Requirement, validate, and populate value.
chapter Dump variable.
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
code 'url="'$url'"'
if [ -n "$url" ];then
    Rcm_parse_url "$url"
	if [ -z "$PHP_URL_HOST" ];then
        error Argument --url is not valid: '`'"$url"'`'.; x
    else
        [ -n "$PHP_URL_SCHEME" ] && url_scheme="$PHP_URL_SCHEME" || url_scheme=https
        if [ -z "$PHP_URL_PORT" ];then
            case "$url_scheme" in
                http) url_port=80;;
                https) url_port=443;;
            esac
        else
            url_port="$PHP_URL_PORT"
        fi
        url_host="$PHP_URL_HOST"
        url_path="$PHP_URL_PATH"
        # Modify variable url, auto add scheme.
        url_path_clean_trailing=$(echo "$url_path" | sed -E 's|/+$||g')
        _url_port=
        if [ -n "$url_port" ];then
            if [[ "$url_scheme" == https && "$url_port" == 443 ]];then
                _url_port=
            elif [[ "$url_scheme" == http && "$url_port" == 80 ]];then
                _url_port=
            else
                _url_port=":${url_port}"
            fi
        fi
        # Modify variable url, auto trim trailing slash, auto add port.
        url="${url_scheme}://${url_host}${_url_port}${url_path_clean_trailing}"
    fi
fi
code 'url="'$url'"'
url_dirname_website_info="${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_parent_name}/subprojects/${project_name}"
code 'url_dirname_website_info="'$url_dirname_website_info'"'
____

if [ -n "$url" ];then
    INDENT+="    " \
    rcm-dig-watch-domain-exists $isfast \
        --domain="$url_host" \
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
rcm-php-setup-adjust-cli-version $isfast \
    --php-version="$php_version" \
    ; [ ! $? -eq 0 ] && x

if [ -n "$is_wsl" ];then
    INDENT+="    " \
    rcm-wsl-setup-lemp-stack $isfast \
        --php-version="$php_version" \
        ; [ ! $? -eq 0 ] && x
fi

INDENT+="    " \
rcm-php-fpm-setup-project-config $isfast \
    --php-version="$php_version" \
    --php-fpm-user="$php_fpm_user" \
    --project-name="$project_name" \
    --project-parent-name="$project_parent_name" \
    --config-suffix-name="drupal" \
    ; [ ! $? -eq 0 ] && x

INDENT+="    " \
rcm-drupal-autoinstaller-nginx $isfast \
    $is_auto_add_group \
    --drupal-version="$drupal_version" \
    --php-version="$php_version" \
    --php-fpm-user="$php_fpm_user" \
    --project-dir="$project_dir" \
    --project-name="$project_name" \
    --project-parent-name="$project_parent_name" \
    --url-scheme="$url_scheme" \
    --url-host="$url_host" \
    --url-port="$url_port" \
    --url-path="$url_path" \
    ; [ ! $? -eq 0 ] && x

if [ -n "$url" ];then
    INDENT+="    " \
    rcm-drupal-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root $isfast \
        --php-version="$php_version" \
        --php-fpm-user="$php_fpm_user" \
        --project-dir="$project_dir" \
        --project-name="$project_name" \
        --project-parent-name="$project_parent_name" \
        --url-scheme="$url_scheme" \
        --url-host="$url_host" \
        --url-port="$url_port" \
        --url-path="$url_path" \
        ; [ ! $? -eq 0 ] && x

    chapter Flush cache.
    code drush cache:rebuild --uri="$url"
    sudo -u "$php_fpm_user" PATH="${project_dir}/drupal/vendor/bin":$PATH $env -s \
        drush cache:rebuild --uri="$url"
    ____
fi

if [ -n "$url" ];then
    chapter Saving URL information.
    code mkdir -p '"'$url_dirname_website_info'"'
    mkdir -p "$url_dirname_website_info"
    cat << EOF >> "${url_dirname_website_info}/website"
URL_DRUPAL=$url
EOF
    fileMustExists "${url_dirname_website_info}/website"
    ____
fi

INDENT+="    " \
rcm-drupal-setup-drush-alias $isfast \
    --project-name="$project_name" \
    --project-parent-name="$project_parent_name" \
    --url-scheme="$url_scheme" \
    --url-host="$url_host" \
    --url-port="$url_port" \
    --url-path="$url_path" \
    && INDENT+="    " \
rcm-drupal-setup-dump-variables $isfast \
    --project-name="$project_name" \
    --project-parent-name="$project_parent_name" \
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
# )
# VALUE=(
# --url
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
