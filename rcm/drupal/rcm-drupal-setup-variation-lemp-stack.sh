#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --fast) fast=1; shift ;;
        --no-auto-add-group) no_auto_add_group=1; shift ;;
        --no-sites-default) no_sites_default=1; shift ;;
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
        --root-sure) root_sure=1; shift ;;
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
_() { echo -n "$INDENT" >&2; echo -n "#" "$@" >&2; }
_,() { echo -n "$@" >&2; }
_.() { echo >&2; }
__() { echo -n "$INDENT" >&2; echo -n "#" '    ' >&2; [ -n "$1" ] && echo "$@" >&2 || echo -n  >&2; }
____() { echo >&2; [ -n "$delay" ] && sleep "$delay"; }

# Functions.
printVersion() {
    echo '0.11.15'
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
   --variation *
        Select the variation setup. Values available from command: rcm-drupal-setup-variation-lemp-stack(eligible).
   --project-name *
        Set the project name as identifier.
        Allowed characters are a-z, 0-9, and underscore (_).
   --url
        Add Drupal public domain. The value can be domain or URL.
        Drupal automatically has address at http://<project>.drupal.localhost/.
        Example: \`example.org\`, \`example.org/path/to/drupal/\`, or \`https://sub.example.org:8080/\`.
   --timezone
        Set the timezone of this machine. Available values: Asia/Jakarta, or other.
   --php-fpm-user
        Set the Unix user that used by PHP FPM.
        Default value is the user that used by web server (the common name is www-data).
        If the user does not exists, it will be autocreate as reguler user.${users}
   --prefix
        Set prefix directory for project. Default to home directory of --php-fpm-user or /usr/local/share.
   --project-container
        Set the container directory for all projects. Available value: drupal-projects, drupal, public_html, or other. Default to drupal-projects.

Other Options (For expert only):
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
   --root-sure
        Bypass root checking.

Dependency:
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
   rcm-drupal-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root:`printVersion`
   rcm-php-fpm-setup-project-config
   rcm-certbot-autoinstaller
   rcm-dig-watch-domain-exists

Download:
   [rcm-php-setup-drupal](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/php/rcm-php-setup-drupal.sh)
   [rcm-drupal-autoinstaller-nginx](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-autoinstaller-nginx.sh)
   [rcm-drupal-setup-wrapper-nginx-setup-drupal](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-wrapper-nginx-setup-drupal.sh)
   [rcm-drupal-setup-drush-alias](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-drush-alias.sh)
   [rcm-drupal-setup-internal-command-cd-drupal](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-internal-command-cd-drupal.sh)
   [rcm-drupal-setup-internal-command-ls-drupal](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-internal-command-ls-drupal.sh)
   [rcm-drupal-setup-dump-variables](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-dump-variables.sh)
   [rcm-drupal-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Command.
command="$1"; shift
if [ -n "$command" ];then
    case "$command" in
        eligible) ;;
        *)
            # Bring back command as argument position.
            set -- "$command" "$@"
            # Reset command.
            command=
    esac
fi

# Functions.
eligible() {
    # chapter Available:
    eligible=()
    if [ -f /etc/os-release ];then
        . /etc/os-release
    fi
    _; _.
    __; _, 'Variation    '; [[ "$ID" == debian && "$VERSION_ID" == 11 ]] && color=rainbow || color=red; $color d11p81d9; _, . Debian 11, '   'PHP 8.1, Drupal ' '9, Drush 11. ; _.; eligible+=("d11p81d9;debian;11")
    __; _, 'Variation   '; [[ "$ID" == debian && "$VERSION_ID" == 11 ]] && color=rainbow || color=red; $color d11p82d10; _, . Debian 11, '   'PHP 8.2, Drupal 10, Drush 12.; _.; eligible+=("d11p82d10;debian;11")
    __; _, 'Variation   '; [[ "$ID" == debian && "$VERSION_ID" == 11 ]] && color=rainbow || color=red; $color d11p83d10; _, . Debian 11, '   'PHP 8.3, Drupal 10, Drush 12. ; _.; eligible+=("d11p83d10;debian;11")
    __; _, 'Variation  '; [[ "$ID" == ubuntu && "$VERSION_ID" == 22.04 ]] && color=rainbow || color=red; $color u2204p81d9; _, . Ubuntu 22.04, PHP 8.1, Drupal ' '9, Drush 11. ; _.; eligible+=("u2204p81d9;ubuntu;22.04")
    __; _, 'Variation '; [[ "$ID" == ubuntu && "$VERSION_ID" == 22.04 ]] && color=rainbow || color=red; $color u2204p82d10; _, . Ubuntu 22.04, PHP 8.2, Drupal 10, Drush 12. ; _.; eligible+=("u2204p82d10;ubuntu;22.04")
    __; _, 'Variation '; [[ "$ID" == ubuntu && "$VERSION_ID" == 22.04 ]] && color=rainbow || color=red; $color u2204p83d10; _, . Ubuntu 22.04, PHP 8.3, Drupal 10, Drush 12. ; _.; eligible+=("u2204p83d10;ubuntu;22.04")
    __; _, 'Variation '; [[ "$ID" == ubuntu && "$VERSION_ID" == 22.04 ]] && color=rainbow || color=red; $color u2204p83d11; _, . Ubuntu 22.04, PHP 8.3, Drupal 11, Drush 13. ; _.; eligible+=("u2204p83d11;ubuntu;22.04")
    __; _, 'Variation    '; [[ "$ID" == debian && "$VERSION_ID" == 12 ]] && color=rainbow || color=red; $color d12p81d9; _, . Debian 12, '   'PHP 8.1, Drupal ' '9, Drush 11. ; _.; eligible+=("d12p81d9;debian;12")
    __; _, 'Variation   '; [[ "$ID" == debian && "$VERSION_ID" == 12 ]] && color=rainbow || color=red; $color d12p82d10; _, . Debian 12, '   'PHP 8.2, Drupal 10, Drush 12. ; _.; eligible+=("d12p82d10;debian;12")
    __; _, 'Variation   '; [[ "$ID" == debian && "$VERSION_ID" == 12 ]] && color=rainbow || color=red; $color d12p83d10; _, . Debian 12, '   'PHP 8.3, Drupal 10, Drush 12. ; _.; eligible+=("d12p83d10;debian;12")
    __; _, 'Variation   '; [[ "$ID" == debian && "$VERSION_ID" == 12 ]] && color=rainbow || color=red; $color d12p83d11; _, . Debian 12, '   'PHP 8.3, Drupal 11, Drush 13. ; _.; eligible+=("d12p83d11;debian;12")
    __; _, 'Variation '; [[ "$ID" == ubuntu && "$VERSION_ID" == 24.04 ]] && color=rainbow || color=red; $color u2404p83d11; _, . Ubuntu 24.04, PHP 8.3, Drupal 11, Drush 13. ; _.; eligible+=("u2404p83d11;ubuntu;24.04")
    for each in "${eligible[@]}";do
        variation=$(cut -d';' -f1 <<< "$each")
        _id=$(cut -d';' -f2 <<< "$each")
        _version_id=$(cut -d';' -f3 <<< "$each")
        if [[ "$_id" == "$ID" && "$_version_id" == "$VERSION_ID" ]];then
            echo $variation
        fi
    done
}
rainbow() {
    local number=yellow
    local other=green
    local word=$1 segment
    local current last
    for ((i = 0 ; i < ${#word} ; i++)); do
        if [[ ${word:$i:1} =~ ^[0-9]+$ ]];then
            current=number
        else
            current=other
        fi
        if [[ -n "$last" && ! "$last" == "$current" ]];then
            ${!last} $segment
            segment=
        fi
        last="$current"
        segment+=${word:$i:1}
    done
    ${!last} $segment
}

# Execute command.
if [[ -n "$command" && $(type -t "$command") == function ]];then
    "$command"
    exit 0
fi

# Title.
title rcm-drupal-setup-variation-lemp-stack
____

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { echo -e "\e[91m""Unable to proceed, "'`'"${line}"'`'" command not found." "\e[39m"; exit 1; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

if [ -z "$root_sure" ];then
    chapter Mengecek akses root.
    if [[ "$EUID" -ne 0 ]]; then
        error This script needs to be run with superuser privileges.; x
    else
        __ Privileges.
    fi
    ____
fi

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

# Requirement, validate, and populate value.
chapter Dump variable.
delay=.5; [ -n "$fast" ] && unset delay
[ -n "$fast" ] && isfast=' --fast' || isfast=''
PREFIX_MASTER=${PREFIX_MASTER:=/usr/local/share/drupal}
code 'PREFIX_MASTER="'$PREFIX_MASTER'"'
PROJECTS_CONTAINER_MASTER=${PROJECTS_CONTAINER_MASTER:=projects}
code 'PROJECTS_CONTAINER_MASTER="'$PROJECTS_CONTAINER_MASTER'"'
code no_auto_add_group="$no_auto_add_group"
code 'no_sites_default="'$no_sites_default'"'
[ -n "$no_auto_add_group" ] && is_no_auto_add_group='' || is_no_auto_add_group=' --auto-add-group'
[ -n "$no_sites_default" ] && is_no_sites_default=' --no-sites-default' || is_no_sites_default=''
if [ -z "$variation" ];then
    error "Argument --variation required."; x
fi
case "$variation" in
    d11p82d10)   os=debian; os_version=11   ; php_version=8.2; drupal_version=10; drush_version=12 ;;
    d11p81d9)    os=debian; os_version=11   ; php_version=8.1; drupal_version=9 ; drush_version=11 ;;
    u2204p82d10) os=ubuntu; os_version=22.04; php_version=8.2; drupal_version=10; drush_version=12 ;;
    u2204p81d9)  os=ubuntu; os_version=22.04; php_version=8.1; drupal_version=9 ; drush_version=11 ;;
    d12p82d10)   os=debian; os_version=12   ; php_version=8.2; drupal_version=10; drush_version=12 ;;
    d12p81d9)    os=debian; os_version=12   ; php_version=8.1; drupal_version=9 ; drush_version=11 ;;
    d12p83d10)   os=debian; os_version=12   ; php_version=8.3; drupal_version=10; drush_version=12 ;;
    d11p83d10)   os=debian; os_version=11   ; php_version=8.3; drupal_version=10; drush_version=12 ;;
    u2204p83d10) os=ubuntu; os_version=22.04; php_version=8.3; drupal_version=10; drush_version=12 ;;
    u2204p83d11) os=ubuntu; os_version=22.04; php_version=8.3; drupal_version=11; drush_version=13 ;;
    d12p83d11)   os=debian; os_version=12   ; php_version=8.3; drupal_version=11; drush_version=13 ;;
    u2404p83d11) os=ubuntu; os_version=24.04; php_version=8.3; drupal_version=11; drush_version=13 ;;
    *) error "Argument --variation is not valid."; x;;
esac
code os="$os"
code os_version="$os_version"
rcm_operand_setup_basic=
case "$os" in
    debian)
        case "$os_version" in
            11) rcm_operand_setup_basic=debian-11-setup-basic ;;
            12) rcm_operand_setup_basic=debian-12-setup-basic ;;
        esac
        ;;
    ubuntu)
        case "$os_version" in
            22.04) rcm_operand_setup_basic=ubuntu-22.04-setup-basic ;;
            24.04) rcm_operand_setup_basic=ubuntu-24.04-setup-basic ;;
        esac
        ;;
esac
if [ -z "$rcm_operand_setup_basic" ];then
    error "Operating System is not support."; x
fi
code php_version="$php_version"
code drupal_version="$drupal_version"
code drush_version="$drush_version"
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
if [ -n "$project_parent_name" ];then
    url_dirname_website_info="${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_parent_name}/subprojects/${project_name}"
else
    url_dirname_website_info="${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_name}"
fi
code 'url_dirname_website_info="'$url_dirname_website_info'"'
code 'timezone="'$timezone'"'
[ -n "$timezone" ] && is_timezone="--timezone=${timezone}" || is_timezone='--timezone-'
____

INDENT+="    " \
rcm $rcm_operand_setup_basic $isfast --root-sure -- $isfast --root-sure \
    --without-update-system- \
    --without-upgrade-system \
    $is_timezone \
    -- \
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

if [ -n "$url" ];then
    INDENT+="    " \
    rcm-dig-watch-domain-exists $isfast --root-sure \
        --domain="$url_host" \
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
rcm-composer-autoinstaller $isfast --root-sure \
    && INDENT+="    " \
rcm-drupal-autoinstaller-nginx $isfast --root-sure \
    $is_no_auto_add_group \
    $is_no_sites_default \
    --drupal-version="$drupal_version" \
    --drush-version="$drush_version" \
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
    rcm-certbot-autoinstaller $isfast --root-sure \
        && INDENT+="    " \
    rcm-drupal-setup-wrapper-nginx-virtual-host-autocreate-php-multiple-root $isfast --root-sure \
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
rcm-drupal-setup-drush-alias $isfast --root-sure \
    --project-name="$project_name" \
    --project-parent-name="$project_parent_name" \
    --url-scheme="$url_scheme" \
    --url-host="$url_host" \
    --url-port="$url_port" \
    --url-path="$url_path" \
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
# --no-sites-default
# --no-auto-add-group
# )
# VALUE=(
# --project-name
# --project-parent-name
# --timezone
# --url
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
# )
# EOF
# clear
