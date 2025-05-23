#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --fast) fast=1; shift ;;
        --no-auto-add-group) no_auto_add_group=1; shift ;;
        --no-drush-install) no_drush_install=1; shift ;;
        --no-sites-default) no_sites_default=1; shift ;;
        --php-fpm-config=*) php_fpm_config+=("${1#*=}"); shift ;;
        --php-fpm-config) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then php_fpm_config+=("$2"); shift; fi; shift ;;
        --php-fpm-user=*) php_fpm_user="${1#*=}"; shift ;;
        --php-fpm-user) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then php_fpm_user="$2"; shift; fi; shift ;;
        --prefix=*) prefix="${1#*=}"; shift ;;
        --prefix) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then prefix="$2"; shift; fi; shift ;;
        --project-container=*) project_container="${1#*=}"; shift ;;
        --project-container) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then project_container="$2"; shift; fi; shift ;;
        --project-name=*) project_name="${1#*=}"; shift ;;
        --project-name) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then project_name="$2"; shift; fi; shift ;;
        --project-parent-name=*) project_parent_name="${1#*=}"; shift ;;
        --project-parent-name) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then project_parent_name="$2"; shift; fi; shift ;;
        --timezone=*) timezone="${1#*=}"; shift ;;
        --timezone) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then timezone="$2"; shift; fi; shift ;;
        --url=*) url="${1#*=}"; shift ;;
        --url) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then url="$2"; shift; fi; shift ;;
        --variation=*) variation="${1#*=}"; shift ;;
        --variation) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then variation="$2"; shift; fi; shift ;;
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
    echo '0.11.31'
}
printHelp() {
    title RCM Drupal Setup
    _ 'Variation '; yellow LEMP Stack; _, . Setup Linux, '(E)'Nginx, MySQL/MariaDB, PHP. ; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    # Populate variable $users.
    users=`cut -d: -f1 /etc/passwd | while read line; do [ -d /home/$line ] && echo " ${line}"; done | tr $'\n' ','`
    nginx_user=
    conf_nginx=`command -v nginx > /dev/null && nginx -V 2>&1 | grep -o -P -- '--conf-path=\K(\S+)'`
    if [ -f "$conf_nginx" ];then
        nginx_user=`grep -o -P '^user\s+\K([^;]+)' "$conf_nginx"`
    fi
    [ -n "$nginx_user" ] && { nginx_user=" ${nginx_user},"; }
    [ -n "$users" ] && users=" Available values:${nginx_user}${users} or other."
    cat << EOF
Usage: rcm-drupal-setup-variation-lemp-stack [options]

Options:
   --timezone
        Set the timezone of this machine. Available values: Asia/Gaza, Asia/Ujung_Pandang, Asia/Jakarta, Asia/Makassar, Asia/Pontianak, Asia/Jayapura, or other.
   --variation *
        Select the variation setup. Values available from command: rcm-drupal-setup-variation-bundle(eligible).
   --project-name *
        Set the project name as identifier.
        Allowed characters are a-z, 0-9, and underscore (_).
   --url
        Add Drupal public domain. The value can be domain or URL.
        Drupal automatically has address at http://<project>.drupal.localhost/.
        Example: \`example.org\`, \`example.org/path/to/drupal/\`, or \`https://sub.example.org:8080/\`.
   --php-fpm-user
        Set the Unix user that used by PHP FPM.
        Default value is the user that used by web server (the common name is www-data).
        If the user does not exists, it will be autocreate as reguler user.${users}
   --php-fpm-config
        Additional PHP-FPM Configuration inside pool directory.
        Available value: [1], [2], [3], [4], [5], [6], [7], or other.
        [1]: pm=ondemand
        [2]: php_flag[display_errors]=on
        [3]: php_value[max_execution_time]=300
        [4]: php_admin_value[memory_limit]=256M
        [5]: php_admin_value[upload_max_filesize]=25M
        [6]: php_admin_value[post_max_size]=1024M
        [7]: php_admin_flag[log_errors]=on
        Multivalue.
   --no-drush-install ^
        If selected, installation will continue to the browser.
        If you are choose Drupal CMS instead Drupal Core, it is recommended to continue installation in the browser.

Other Options (For expert only):
   --prefix
        Set prefix directory for project.
        Default to home directory of --php-fpm-user or /usr/local/share.
   --project-container
        Set the container directory for all projects.
        Available value: drupal-projects, drupal, public_html, or other.
        Default to drupal-projects.
   --project-parent-name
        Set the project parent name. The parent is not have to installed before.
   --no-sites-default ^
        Prevent installing drupal inside directory sites/default.
        Drupal will install inside sites/[<project-parent-name>--]<project-name>.
   --no-auto-add-group ^
        By default, if Nginx User cannot access PHP-FPM's Directory, auto add group of PHP-FPM User to Nginx User.
        Use this flag to omit that default action.

Global Options.
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.

Dependency:
   rcm-nginx-apt
   rcm-mariadb-apt
   rcm-drupal-setup-variation-bundle:`printVersion`

Download:
   [rcm-drupal-setup-variation-bundle](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-variation-bundle.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-drupal-setup-variation-lemp-stack
____

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'`cut -d: -f1 <<< "${line}"`'`'.; x; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

[ "$EUID" -ne 0 ] && { error This script needs to be run with superuser privileges.; x; }

#  Functions.
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
resolve_relative_path() {
    if [ -d "$1" ];then
        cd "$1" || return 1
        pwd
    elif [ -e "$1" ];then
        if [ ! "${1%/*}" = "$1" ]; then
            cd "${1%/*}" || return 1
        fi
        echo "$(pwd)/${1##*/}"
    else
        return 1
    fi
}

# Requirement, validate, and populate value.
chapter Dump variable.
[ -n "$fast" ] && isfast=' --fast' || isfast=''
if [ -f /etc/os-release ];then
    . /etc/os-release
fi
os="$ID"
os_version="$VERSION_ID"
code os="$os"
code os_version="$os_version"
operand_setup_basic=
case "$os" in
    debian)
        case "$os_version" in
            11) operand_setup_basic=debian-11-setup-basic ;;
            12) operand_setup_basic=debian-12-setup-basic ;;
        esac
        ;;
    ubuntu)
        case "$os_version" in
            22.04) operand_setup_basic=ubuntu-22.04-setup-basic ;;
            24.04) operand_setup_basic=ubuntu-24.04-setup-basic ;;
        esac
        ;;
esac
if [ -z "$variation" ];then
    error "Argument --variation required."; x
fi
if [ -z "$operand_setup_basic" ];then
    error "Operating System is not support."; x
fi
is_wsl=
if [ -f /proc/sys/kernel/osrelease ];then
    read osrelease </proc/sys/kernel/osrelease
    if [[ "$osrelease" =~ microsoft || "$osrelease" =~ Microsoft ]];then
        is_wsl=1
    fi
fi
code 'is_wsl="'$is_wsl'"'
code 'timezone="'$timezone'"'
if [ -z "$project_name" ];then
    error "Argument --project-name required."; x
fi
code 'project_name="'$project_name'"'
if ! validateMachineName "$project_name" project_name;then x; fi
# Advanced user can fill variable $project_parent_name from command line.
code 'project_parent_name="'$project_parent_name'"'
if [ -n "$project_parent_name" ];then
    if ! validateMachineName "$project_parent_name" project_parent_name;then x; fi
fi
code no_auto_add_group="$no_auto_add_group"
code 'no_sites_default="'$no_sites_default'"'
[ -n "$no_auto_add_group" ] && is_no_auto_add_group='' || is_no_auto_add_group=' --auto-add-group'
[ -n "$no_sites_default" ] && is_no_sites_default=' --no-sites-default' || is_no_sites_default=''
code 'prefix="'$prefix'"'
if [ -n "$prefix" ];then
    if [ -d "$prefix" ];then
        if [ ! "${prefix:0:1}" == / ];then
            prefix=$(resolve_relative_path "$prefix")
        fi
    else
        error Directory prefix is not exists; x
    fi
fi
code 'prefix="'$prefix'"'
code 'no_drush_install="'$no_drush_install'"'
[ -n "$no_drush_install" ] && is_no_drush_install=' --no-drush-install' || is_no_drush_install=''
is_php_fpm_config=
is_php_fpm_config_array=()
# Dump array dengan single quote.
e; magenta 'php_fpm_config=('
first=1
for each in "${php_fpm_config[@]}";do
    if [ -n "$first" ];then
        magenta "'""$each""'"; first=
    else
        magenta " '""$each""'";
    fi
    [[ "$each" =~ ' ' ]] && is_php_fpm_config+=" --php-fpm-config='${each}'" || is_php_fpm_config+=" --php-fpm-config=${each}"
    is_php_fpm_config_array+=("--php-fpm-config=${each}")
done
magenta ')'; _.
____

INDENT+="    " \
rcm $operand_setup_basic -- \
    $isfast \
    --without-update-system- \
    --without-upgrade-system \
    --timezone="$timezone" \
    -- \
    && INDENT+="    " \
rcm-nginx-apt $isfast \
    && INDENT+="    " \
rcm-mariadb-apt $isfast \
    && INDENT+="    " \
rcm-drupal-setup-variation-bundle $isfast \
    $is_no_auto_add_group \
    $is_no_sites_default \
    $is_no_drush_install \
    --variation="$variation" \
    --project-name="$project_name" \
    --project-parent-name="$project_parent_name" \
    --url="$url" \
    --php-fpm-user="$php_fpm_user" \
    "${is_php_fpm_config_array[@]}" \
    --prefix="$prefix" \
    --project-container="$project_container" \
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
# --no-sites-default
# --no-auto-add-group
# --no-drush-install
# )
# VALUE=(
# --timezone
# --project-name
# --project-parent-name
# --url
# --php-fpm-user
# --prefix
# --project-container
# --variation
# )
# MULTIVALUE=(
# --php-fpm-config
# )
# FLAG_VALUE=(
# )
# CSV=(
# )
# EOF
# clear
