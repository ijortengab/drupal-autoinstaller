#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --auto-add-group) auto_add_group=1; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then domain="$2"; shift; fi; shift ;;
        --domain-strict) domain_strict=1; shift ;;
        --fast) fast=1; shift ;;
        --php-fpm-user=*) php_fpm_user="${1#*=}"; shift ;;
        --php-fpm-user) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then php_fpm_user="$2"; shift; fi; shift ;;
        --prefix=*) prefix="${1#*=}"; shift ;;
        --prefix) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then prefix="$2"; shift; fi; shift ;;
        --project-container=*) project_container="${1#*=}"; shift ;;
        --project-container) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then project_container="$2"; shift; fi; shift ;;
        --project-name=*) project_name="${1#*=}"; shift ;;
        --project-name) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then project_name="$2"; shift; fi; shift ;;
        --project-parent-name=*) project_parent_name="${1#*=}"; shift ;;
        --project-parent-name) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then project_parent_name="$2"; shift; fi; shift ;;
        --root-sure) root_sure=1; shift ;;
        --timezone=*) timezone="${1#*=}"; shift ;;
        --timezone) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then timezone="$2"; shift; fi; shift ;;
        --variation=*) variation="${1#*=}"; shift ;;
        --variation) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then variation="$2"; shift; fi; shift ;;
        --with-update-system) update_system=1; shift ;;
        --without-update-system) update_system=0; shift ;;
        --with-upgrade-system) upgrade_system=1; shift ;;
        --without-upgrade-system) upgrade_system=0; shift ;;
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
    echo '0.11.6'
}
printHelp() {
    title RCM Drupal Setup
    _ 'Variation '; yellow LEMP Stack; _, . Setup Linux, '(E)'Nginx, MySQL/MariaDB, PHP. ; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-drupal-setup-variation-lemp-stack [options]

Options:
   --variation *
        Set the variation.
   --project-name *
        Set the project name. This should be in machine name format.
   --project-parent-name
        Set the project parent name. The parent is not have to installed before.
   --domain
        Set the domain.
   --timezone
        Set the timezone of this machine. Available values: Asia/Jakarta, or other.
   --domain-strict ^
        Prevent installing drupal inside directory sites/default.
   --php-fpm-user
        Set the Unix user that used by PHP FPM. Default value is the user that used by web server. Available values:${nginx_user}`cut -d: -f1 /etc/passwd | while read line; do [ -d /home/$line ] && echo " ${line}"; done | tr $'\n' ','` or other. If the user does not exists, it will be autocreate as reguler user.
   --prefix
        Set prefix directory for project. Default to home directory of --php-fpm-user or /usr/local/share.
   --project-container
        Set the container directory for all projects. Available value: drupal-projects, drupal, public_html, or other. Default to drupal-projects.
   --auto-add-group ^
        If Nginx User cannot access PHP-FPM's Directory, auto add group of PHP-FPM User to Nginx User.
   --without-update-system ^
        Skip execute update system. Default to --with-update-system.
   --without-upgrade-system ^
        Skip execute upgrade system. Default to --with-upgrade-system.

Global Options.
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.
   --root-sure
        Bypass root checking.

Dependency:
   rcm-ubuntu-22.04-setup-basic
   rcm-ubuntu-24.04-setup-basic
   rcm-debian-11-setup-basic
   rcm-debian-12-setup-basic
   rcm-nginx-autoinstaller
   rcm-mariadb-autoinstaller
   rcm-php-autoinstaller
   rcm-php-setup-adjust-cli-version
   rcm-php-setup-drupal:`printVersion`
   rcm-wsl-setup-lemp-stack
   rcm-composer-autoinstaller
   rcm-drupal-autoinstaller-nginx:`printVersion`
   rcm-drupal-setup-wrapper-nginx-setup-drupal:`printVersion`
   rcm-drupal-setup-drush-alias:`printVersion`
   rcm-drupal-setup-internal-command-cd-drupal:`printVersion`
   rcm-drupal-setup-internal-command-ls-drupal:`printVersion`
   rcm-drupal-setup-dump-variables:`printVersion`
   rcm-php-fpm-setup-project-config

Download:
   [rcm-php-setup-drupal](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/php/rcm-php-setup-drupal.sh)
   [rcm-drupal-autoinstaller-nginx](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-autoinstaller-nginx.sh)
   [rcm-drupal-setup-wrapper-nginx-setup-drupal](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-wrapper-nginx-setup-drupal.sh)
   [rcm-drupal-setup-drush-alias](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-drush-alias.sh)
   [rcm-drupal-setup-internal-command-cd-drupal](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-internal-command-cd-drupal.sh)
   [rcm-drupal-setup-internal-command-ls-drupal](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-internal-command-ls-drupal.sh)
   [rcm-drupal-setup-dump-variables](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-dump-variables.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { echo -e "\e[91m""Unable to proceed, "'`'"${line}"'`'" command not found." "\e[39m"; exit 1; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

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

# Title.
title rcm-drupal-setup-variation-lemp-stack
____

# Requirement, validate, and populate value.
chapter Dump variable.
delay=.5; [ -n "$fast" ] && unset delay
code update_system="$update_system"
code upgrade_system="$upgrade_system"
[ -n "$fast" ] && isfast=' --fast' || isfast=''
[ -n "$auto_add_group" ] && is_auto_add_group=' --auto-add-group' || is_auto_add_group=''
[[ "$update_system" == "0" ]] && is_without_update_system=' --without-update-system' || is_without_update_system=''
[[ "$upgrade_system" == "0" ]] && is_without_upgrade_system=' --without-upgrade-system' || is_without_upgrade_system=''
if [ -z "$variation" ];then
    error "Argument --variation required."; x
fi
# Variation 1. Debian 11,    PHP 8.2, Drupal 10, Drush 12.
# Variation 2. Debian 11,    PHP 8.1, Drupal  9, Drush 11.
# Variation 3. Ubuntu 22.04, PHP 8.2, Drupal 10, Drush 12.
# Variation 4. Ubuntu 22.04, PHP 8.1, Drupal  9, Drush 11.
# Variation 5. Debian 12,    PHP 8.2, Drupal 10, Drush 12.
# Variation 6. Debian 12,    PHP 8.1, Drupal  9, Drush 11.
# Variation 7. Debian 12,    PHP 8.3, Drupal 10, Drush 12.
# Variation 8. Debian 11,    PHP 8.3, Drupal 10, Drush 12.
# Variation 9. Ubuntu 22.04, PHP 8.3, Drupal 10, Drush 12.
case "$variation" in
    1) os=debian; os_version=11   ; php_version=8.2; drupal_version=10; drush_version=12 ;;
    2) os=debian; os_version=11   ; php_version=8.1; drupal_version=9 ; drush_version=11 ;;
    3) os=ubuntu; os_version=22.04; php_version=8.2; drupal_version=10; drush_version=12 ;;
    4) os=ubuntu; os_version=22.04; php_version=8.1; drupal_version=9 ; drush_version=11 ;;
    5) os=debian; os_version=12   ; php_version=8.2; drupal_version=10; drush_version=12 ;;
    6) os=debian; os_version=12   ; php_version=8.1; drupal_version=9 ; drush_version=11 ;;
    7) os=debian; os_version=12   ; php_version=8.3; drupal_version=10; drush_version=12 ;;
    8) os=debian; os_version=11   ; php_version=8.3; drupal_version=10; drush_version=12 ;;
    10) os=ubuntu; os_version=22.04; php_version=8.3; drupal_version=11; drush_version=13 ;;
    11) os=debian; os_version=12   ; php_version=8.3; drupal_version=11; drush_version=13 ;;
    12) os=ubuntu; os_version=24.04; php_version=8.3; drupal_version=11; drush_version=13 ;;
    *) error "Argument --variation is not valid."; x;;
esac

code os="$os"
code os_version="$os_version"
code php_version="$php_version"
code drupal_version="$drupal_version"
code drush_version="$drush_version"
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
code 'domain="'$domain'"'
is_wsl=
if [ -f /proc/sys/kernel/osrelease ];then
    read osrelease </proc/sys/kernel/osrelease
    if [[ "$osrelease" =~ microsoft || "$osrelease" =~ Microsoft ]];then
        is_wsl=1
    fi
fi
code 'is_wsl="'$is_wsl'"'
if [ -z "$php_fpm_user" ];then
    # It will auto populate by rcm-drupal-autoinstaller-nginx.
    php_fpm_user="-"
    prefix="-"
fi
code 'php_fpm_user="'$php_fpm_user'"'
if [[ -n "$php_fpm_user" && -z "$prefix" ]];then
    prefix=$(getent passwd "$php_fpm_user" | cut -d: -f6 )
fi
if [ -z "$project_container" ];then
    project_container=drupal-projects
fi
code 'prefix="'$prefix'"'
code 'project_container="'$project_container'"'
code 'auto_add_group="'$auto_add_group'"'
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

INDENT+="    " \
rcm-$os-$os_version-setup-basic $isfast --root-sure \
    $is_without_update_system \
    $is_without_upgrade_system \
    --timezone="$timezone" \
    && INDENT+="    " \
rcm-nginx-autoinstaller $isfast --root-sure \
    && INDENT+="    " \
rcm-mariadb-autoinstaller $isfast --root-sure \
    && INDENT+="    " \
rcm-php-autoinstaller $isfast --root-sure \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-php-setup-adjust-cli-version $isfast --root-sure \
    --php-version="$php_version" \
    && INDENT+="    " \
rcm-php-setup-drupal $isfast --root-sure \
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
rcm-composer-autoinstaller $isfast --root-sure \
    && INDENT+="    " \
rcm-drupal-autoinstaller-nginx $isfast --root-sure \
    $is_auto_add_group \
    --drupal-version="$drupal_version" \
    --drush-version="$drush_version" \
    --php-version="$php_version" \
    --php-fpm-user="$php_fpm_user" \
    --prefix="$prefix" \
    --project-container="$project_container" \
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
        --prefix="$prefix" \
        --project-container="$project_container" \
        && INDENT+="    " \
    rcm-drupal-setup-wrapper-nginx-setup-drupal $isfast --root-sure \
        --php-version="$php_version" \
        --project-name="$project_name" \
        --project-parent-name="$project_parent_name" \
        --subdomain="$domain" \
        --domain="localhost" \
        --php-fpm-user="$php_fpm_user" \
        --prefix="$prefix" \
        --project-container="$project_container" \
        && INDENT+="    " \
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
e If you want to see the credentials again, please execute this command:
[ -n "$project_parent_name" ] && has_project_parent_name=' --project-parent-name='"'${project_parent_name}'" || has_project_parent_name=''
[ -n "$domain" ] && has_domain=' --domain='"'${domain}'" || has_domain=''
code rcm drupal-setup-dump-variables${isfast} --non-interactive -- --project-name="'${project_name}'"${has_project_parent_name}${has_domain}
e It is recommended for you to level up file system directory outside web root, please execute this command:
code rcm install drupal-adjust-file-system-outside-web-root --source drupal
code rcm drupal-adjust-file-system-outside-web-root${isfast} -- --project-name="'${project_parent_name:-$project_name}'"
e There are helpful commands to browse all projects:
code cd-drupal --help
code ls-drupal --help
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
# --auto-add-group
# )
# VALUE=(
# --project-name
# --project-parent-name
# --timezone
# --domain
# --php-fpm-user
# --prefix
# --project-container
# --variation
# )
# MULTIVALUE=(
# )
# FLAG_VALUE=(
# )
# CSV=(
    # 'long:--with-update-system,parameter:update_system'
    # 'long:--without-update-system,parameter:update_system,flag_option:reverse'
    # 'long:--with-upgrade-system,parameter:upgrade_system'
    # 'long:--without-upgrade-system,parameter:upgrade_system,flag_option:reverse'
# )
# EOF
# clear
