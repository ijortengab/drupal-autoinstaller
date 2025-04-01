#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --auto-add-group) auto_add_group=1; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then domain="$2"; shift; fi; shift ;;
        --domain-strict) domain_strict=1; shift ;;
        --drupal-version=*) drupal_version="${1#*=}"; shift ;;
        --drupal-version) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then drupal_version="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --php-fpm-user=*) php_fpm_user="${1#*=}"; shift ;;
        --php-fpm-user) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then php_fpm_user="$2"; shift; fi; shift ;;
        --php-version=*) php_version="${1#*=}"; shift ;;
        --php-version) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then php_version="$2"; shift; fi; shift ;;
        --prefix=*) prefix="${1#*=}"; shift ;;
        --prefix) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then prefix="$2"; shift; fi; shift ;;
        --project-container=*) project_container="${1#*=}"; shift ;;
        --project-container) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then project_container="$2"; shift; fi; shift ;;
        --project-name=*) project_name="${1#*=}"; shift ;;
        --project-name) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then project_name="$2"; shift; fi; shift ;;
        --project-parent-name=*) project_parent_name="${1#*=}"; shift ;;
        --project-parent-name) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then project_parent_name="$2"; shift; fi; shift ;;
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
    echo '0.11.27'
}
printHelp() {
    title RCM Drupal Setup
    _ 'Variation '; yellow Default; _, . Just Drupal without LEMP Stack setup. ; _.
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
    # Populate variable $single_line and $multi_line.
    unset count
    declare -i count
    count=0
    single_line=
    multi_line=
    while read line;do
        if [ -d /etc/php/$line/fpm ];then
            if [ $count -gt 0 ];then
                single_line+=", "
            fi
            count+=1
            single_line+="[${count}]"
            multi_line+=$'\n''        '"[${count}]: "${line}
        fi
    done <<< `ls /etc/php/`
    if [ -n "$single_line" ];then
        single_line=" Available values: ${single_line}, or other."
    fi
    if [ -n "$multi_line" ];then
        multi_line="$multi_line"
    fi
    cat << EOF
Usage: rcm-drupal-setup-variation-default [options]

Options:
   --drupal-version *
        Set the version of Drupal. Available values: 10, 11, or other.
   --php-version *
        Set the version of PHP.${single_line}${multi_line}
   --project-name *
        Set the project name as identifier.
        Allowed characters are a-z, 0-9, and underscore (_).
   --domain
        Set the domain.
   --domain-strict ^
        Prevent installing drupal inside directory sites/default.
        Just skip it if you are confused.
   --php-fpm-user
        Set the Unix user that used by PHP FPM. Default value is the user that used by web server.${users} If the user does not exists, it will be autocreate as reguler user.
   --prefix
        Set prefix directory for project. Default to home directory of --php-fpm-user or /usr/local/share.
   --project-container
        Set the container directory for all projects. Available value: drupal-projects, drupal, public_html, or other. Default to drupal-projects.
   --auto-add-group ^
        If Nginx User cannot access PHP-FPM's Directory, auto add group of PHP-FPM User to Nginx User.

Global Options.
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.

Other Options:
   --project-parent-name
        Set the project parent name. The parent is not have to installed before. For expert only.

Dependency:
   nginx
   rcm-php-setup-adjust-cli-version
   rcm-wsl-setup-lemp-stack
   rcm-composer-autoinstaller
   rcm-drupal-autoinstaller-nginx:`printVersion`
   rcm-drupal-setup-wrapper-nginx-setup-drupal:`printVersion`
   rcm-drupal-setup-drush-alias:`printVersion`
   rcm-drupal-setup-internal-command-cd-drupal:`printVersion`
   rcm-drupal-setup-internal-command-ls-drupal:`printVersion`
   rcm-drupal-setup-dump-variables:`printVersion`
   rcm-php-fpm-setup-project-config
   rcm-dig-watch-domain-exists

Download:
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

# Title.
title rcm-drupal-setup-variation-default
____

[ "$EUID" -ne 0 ] && { error This script needs to be run with superuser privileges.; x; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'`cut -d: -f1 <<< "${line}"`'`'.; x; }
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

# Requirement, validate, and populate value.
chapter Dump variable.
[ -n "$fast" ] && isfast=' --fast' || isfast=''
code auto_add_group="$auto_add_group"
[ -n "$auto_add_group" ] && is_auto_add_group=' --auto-add-group' || is_auto_add_group=''
if [ -z "$php_version" ];then
    error "Argument --php-version required."; x
fi
if [ -z "$drupal_version" ];then
    error "Argument --drupal-version required."; x
fi
code php_version="$php_version"
code drupal_version="$drupal_version"
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
____

if [ -n "$domain" ];then
    INDENT+="    " \
    rcm-dig-watch-domain-exists $isfast \
        --domain="$domain" \
        --waiting-time="60" \
        ; [ ! $? -eq 0 ] && x
fi

# Di baris ini seharusnya sudah terinstall nginx.
chapter Populate variables.
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

# Di baris ini seharusnya sudah exists user linux $php_fpm_user.
chapter Populate variables.
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
# Hanya populate, tidak harus exists direktori ini.
project_dir="${prefix}/${project_container}"
if [ -n "$project_parent_name" ];then
    project_dir+="/${project_parent_name}"
else
    project_dir+="/${project_name}"
fi
code 'project_dir="'$project_dir'"'
____

INDENT+="    " \
rcm-composer-autoinstaller $isfast \
    && INDENT+="    " \
rcm-drupal-autoinstaller-nginx $isfast \
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
    rcm-drupal-setup-wrapper-nginx-setup-drupal $isfast \
        --php-version="$php_version" \
        --project-name="$project_name" \
        --project-parent-name="$project_parent_name" \
        --domain="$domain" \
        --php-fpm-user="$php_fpm_user" \
        --project-dir="$project_dir" \
        && INDENT+="    " \
    rcm-drupal-setup-wrapper-nginx-setup-drupal $isfast \
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
    rcm-certbot-deploy-nginx $isfast \
        --domain="${domain}" \
        ; [ ! $? -eq 0 ] && x
fi

INDENT+="    " \
rcm-drupal-setup-drush-alias $isfast \
    --project-name="$project_name" \
    --project-parent-name="$project_parent_name" \
    --domain="$domain" \
    && INDENT+="    " \
rcm-drupal-setup-internal-command-cd-drupal $isfast \
    && INDENT+="    " \
rcm-drupal-setup-internal-command-ls-drupal $isfast \
    && INDENT+="    " \
rcm-drupal-setup-dump-variables $isfast \
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
# --domain-strict
# --auto-add-group
# )
# VALUE=(
# --project-name
# --project-parent-name
# --drupal-version
# --php-version
# --domain
# --php-fpm-user
# --prefix
# --project-container
# )
# MULTIVALUE=(
# )
# FLAG_VALUE=(
# )
# CSV=(
# )
# EOF
# clear
