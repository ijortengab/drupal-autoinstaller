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
    echo '0.11.8'
}
printHelp() {
    title RCM Drupal Setup
    _ 'Variation '; yellow Default; _, . Just Drupal without LEMP Stack setup. ; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    nginx_user=
    conf_nginx=`command -v nginx > /dev/null && command -v nginx > /dev/null && nginx -V 2>&1 | grep -o -P -- '--conf-path=\K(\S+)'`
    if [ -f "$conf_nginx" ];then
        nginx_user=`grep -o -P '^user\s+\K([^;]+)' "$conf_nginx"`
    fi
    [ -n "$nginx_user" ] && { nginx_user=" ${nginx_user},"; }
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
   --project-parent-name
        Set the parent to create Drupal MultiSite, or skip to make an independent codebase. Value available from command: ls-drupal(), or other. The parent is not have to installed before.
   --project-name *
        Set the project name as identifier. This should be in machine name format.
   --domain
        Set the domain.
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
   rcm-drupal-wrapper-certbot-deploy-nginx:`printVersion`
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
title rcm-drupal-setup-variation-default
____

# Requirement, validate, and populate value.
chapter Dump variable.
delay=.5; [ -n "$fast" ] && unset delay
[ -n "$fast" ] && isfast=' --fast' || isfast=''
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

if [ -n "$domain" ];then
    INDENT+="    " \
    rcm-dig-watch-domain-exists $isfast --root-sure \
        --domain="$domain" \
        --waiting-time="60" \
        ; [ ! $? -eq 0 ] && x
fi

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
rcm-composer-autoinstaller $isfast --root-sure \
    && INDENT+="    " \
rcm-drupal-autoinstaller-nginx $isfast --root-sure \
    $is_auto_add_group \
    --domain="$domain" \
    --drupal-version="$drupal_version" \
    --php-version="$php_version" \
    --php-fpm-user="$php_fpm_user" \
    --prefix="$prefix" \
    --project-container="$project_container" \
    --project-name="$project_name" \
    --project-parent-name="$project_parent_name" \
    ; [ ! $? -eq 0 ] && x

if [ -n "$domain" ];then
    INDENT+="    " \
    rcm-dig-is-name-exists $isfast --root-sure \
        --domain="$domain" \
        && INDENT+="    " \
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
    rcm-drupal-wrapper-certbot-deploy-nginx $isfast --root-sure \
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
