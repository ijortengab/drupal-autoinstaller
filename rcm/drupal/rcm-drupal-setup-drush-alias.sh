#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --domain=*) domain="${1#*=}"; shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then domain="$2"; shift; fi; shift ;;
        --fast) fast=1; shift ;;
        --project-name=*) project_name="${1#*=}"; shift ;;
        --project-name) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then project_name="$2"; shift; fi; shift ;;
        --project-parent-name=*) project_parent_name="${1#*=}"; shift ;;
        --project-parent-name) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then project_parent_name="$2"; shift; fi; shift ;;
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
e() { echo -n "$INDENT" >&2; echo -n "$@" >&2; }
_() { echo -n "$INDENT" >&2; echo -n "#" "$@" >&2; }
_,() { echo -n "$@" >&2; }
_.() { echo >&2; }
__() { echo -n "$INDENT" >&2; echo -n "#" '    ' >&2; [ -n "$1" ] && echo "$@" >&2 || echo -n  >&2; }
____() { echo >&2; [ -n "$delay" ] && sleep "$delay"; }

# Functions.
printVersion() {
    echo '0.11.10'
}
printHelp() {
    title RCM Drupal Setup
    _ 'Variation '; yellow Drush Alias; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << 'EOF'
Usage: rcm-drupal-setup-drush-alias [options]

Options:
   --project-name
        Set the project name. This should be in machine name format.
   --project-parent-name
        Set the project parent name.
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

Environment Variables:
   BINARY_DIRECTORY
        Default to $__DIR__
   PREFIX_MASTER
        Default to /usr/local/share/drupal
   PROJECTS_CONTAINER_MASTER
        Default to projects
   SITES_MASTER
        Default to sites
   BINARY_MASTER
        Default to bin
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-drupal-setup-drush-alias
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

# Functions.
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
isFileExists() {
    # global used:
    # global modified: found, notfound
    # function used: __
    if [[ -f "$1" && ! -s "$1" ]];then
        __ Empty file detected.
        __; magenta rm "$1"; _.
        rm "$1"
    fi
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
backupDir() {
    local oldpath="$1" i newpath
    i=1
    newpath="${oldpath}.${i}"
    if [ -e "$newpath" ]; then
        let i++
        newpath="${oldpath}.${i}"
        while [ -e "$newpath" ] ; do
            let i++
            newpath="${oldpath}.${i}"
        done
    fi
    mv "$oldpath" "$newpath"
}
link_symbolic() {
    local source="$1"
    local target="$2"
    local sudo="$3"
    local create
    [ -e "$source" ] || { error Source not exist: $source.; x; }
    [ -f "$source" ] || { error Source exists but not file: $source.; x; }
    [ -n "$target" ] || { error Target not defined.; x; }
    [[ $(type -t backupFile) == function ]] || { error Function backupFile not found.; x; }
    [[ $(type -t backupDir) == function ]] || { error Function backupDir not found.; x; }

    chapter Membuat symbolic link.
    __ source: '`'$source'`'
    __ target: '`'$target'`'
    if [ -f "$target" ];then
        if [ -h "$target" ];then
            __ Path target saat ini sudah merupakan file symbolic link: '`'$target'`'
            local _readlink=$(readlink "$target")
            __; magenta readlink "$target"; _.
            _ $_readlink; _.
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
            __; _, Mengecek apakah link merujuk ke '`'$source'`':' '
            if [[ "$source" == "$_dereference" ]];then
                _, merujuk.; _.
            else
                _, tidak merujuk.; _.
                __ Melakukan backup.
                backupFile move "$target"
                create=1
            fi
        else
            __ Melakukan backup regular file: '`'"$target"'`'.
            backupFile move "$target"
            create=1
        fi
    elif [ -d "$target" ];then
        __ Melakukan backup direktori: '`'"$target"'`'.
        backupDir "$target"
        create=1
    else
        create=1
    fi
    if [ -n "$create" ];then
        __ Membuat symbolic link: '`'$target'`'.
        local target_parent=$(dirname "$target")
        code mkdir -p "$target_parent"
        mkdir -p "$target_parent"
        local source_relative=$(realpath -s --relative-to="$target_parent" "$source")
        if [ -n "$sudo" ];then
            code sudo -u '"'$sudo'"' ln -s '"'$source_relative'"' '"'$target'"'
            sudo -u "$sudo" ln -s "$source_relative" "$target"
        else
            code ln -s '"'$source_relative'"' '"'$target'"'
            ln -s "$source_relative" "$target"
        fi
        if [ $? -eq 0 ];then
            __; green Symbolic link berhasil dibuat.; _.
        else
            __; red Symbolic link gagal dibuat.; x
        fi
    fi
    ____
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

# Require, validate, and populate value.
chapter Dump variable.
delay=.5; [ -n "$fast" ] && unset delay
__FILE__=$(resolve_relative_path "$0")
__DIR__=$(dirname "$__FILE__")
BINARY_DIRECTORY=${BINARY_DIRECTORY:=$__DIR__}
code 'BINARY_DIRECTORY="'$BINARY_DIRECTORY'"'
if [ -z "$project_name" ];then
    error "Argument --project-name required."; x
fi
code 'domain="'$domain'"'
code 'project_name="'$project_name'"'
code 'project_parent_name="'$project_parent_name'"'
project_dir_basename="$project_name"
drupal_fqdn_localhost="$project_name".drupal.localhost
[ -n "$project_parent_name" ] && {
    drupal_fqdn_localhost="$project_name"."$project_parent_name".drupal.localhost
    project_dir_basename="$project_parent_name"
}
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
BINARY_MASTER=${BINARY_MASTER:=bin}
code 'BINARY_MASTER="'$BINARY_MASTER'"'
SITES_MASTER=${SITES_MASTER:=sites}
code 'SITES_MASTER="'$SITES_MASTER'"'
NEW_VERSION=`printVersion`
code 'NEW_VERSION="'$NEW_VERSION'"'
mktemp=
____

target_master="${PREFIX_MASTER}/${BINARY_MASTER}"
chapter Mengecek direktori master binary '`'$target_master'`'.
isDirExists "$target_master"
____

if [ -n "$notfound" ];then
    chapter Membuat direktori master binary.
    code mkdir -p '"'$target_master'"'
    mkdir -p "$target_master"
    dirMustExists "$target_master"
    ____
fi

list_uri=("${drupal_fqdn_localhost}")
if [ -n "$domain" ];then
    list_uri+=("${domain}")
    list_uri+=("${domain}.localhost")
fi

for uri in "${list_uri[@]}";do
    filename="${uri}"
    chapter Script Shortcut ${filename}
    fullpath="${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir_basename}/${SITES_MASTER}/${filename}"
    dirname="${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir_basename}/${SITES_MASTER}"
    isFileExists "$fullpath"
    if [ -n "$found" ];then
        __ Mengecek versi '`'${filename}'`' command.
        __; magenta ${filename} --version; _.
        if [ -z "$mktemp" ];then
            mktemp=$(mktemp -p /dev/shm)
        fi
        "$fullpath" --version 2>/dev/null | tee $mktemp
        old_version=$(head -1 $mktemp)
        if [[ "$old_version" =~ [^0-9\.]+ ]];then
            old_version=0
        fi
        vercomp $NEW_VERSION $old_version
        if [[ $? -eq 1 ]];then
            __ Command perlu diupdate. Versi saat ini ${NEW_VERSION}.
            found=
            notfound=1
        else
            __ Command tidak perlu diupdate. Versi saat ini ${NEW_VERSION}.
        fi
    fi
    if [ -n "$notfound" ];then
        __ Membuat file '`'"$fullpath"'`'.
        mkdir -p "$dirname"
        touch "$fullpath"
        chmod a+x "$fullpath"
        cat << 'EOF' > "$fullpath"
#!/bin/bash
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) version=1; shift ;;
        --[^-]*) shift ;;
        *) _new_arguments+=("$1"); shift ;;
    esac
done
set -- "${_new_arguments[@]}"
unset _new_arguments

printVersion() {
    echo '__NEW_VERSION__'
}
[ -n "$version" ] && { printVersion; exit 1; }

[[ -f "$0" && ! "$0" == $(command -v bash) ]] && { echo -e "\e[91m""Usage: . "$(basename "$0") "\e[39m"; exit 1; }
PREFIX_MASTER=__PREFIX_MASTER__
PROJECTS_CONTAINER_MASTER=__PROJECTS_CONTAINER_MASTER__
PROJECT_ROOT=__PROJECT_ROOT__
_target="${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${PROJECT_ROOT}/drupal"
_dereference=$(stat "$_target" -c %N)
PROJECT_ROOT=$(grep -Eo "' -> '.*'$" <<< "$_dereference" | sed -E "s/' -> '(.*)'$/\1/")
echo
echo -n Waiting...
export SITE=__URI__
export PROJECT_ROOT="$PROJECT_ROOT"
export SITE_DIR=$("$PROJECT_ROOT/vendor/bin/drush" --uri="$SITE" status --field=site)
export WEB_ROOT=$("$PROJECT_ROOT/vendor/bin/drush" --uri="$SITE" status --field=root)
printf "\r\033[K"
echo export PROJECT_ROOT='"'$PROJECT_ROOT'"'
echo export WEB_ROOT='"'$WEB_ROOT'"'
echo export '       'SITE='"'"$SITE"'"'
echo export '   'SITE_DIR='"'$SITE_DIR'"'
echo -e alias '      '"\e[95m"' 'drush"\e[39m"='"''$PROJECT_ROOT'/vendor/bin/drush --uri='$SITE''"'
echo
echo cd '"$PROJECT_ROOT"'' && [ -f .rc ] && . .rc'
alias drush="$PROJECT_ROOT/vendor/bin/drush --uri=$SITE"
echo
# rc means run commands. @see: https://superuser.com/a/173167
cd "$PROJECT_ROOT" && [ -f .rc ] && . .rc
EOF
        sed -i "s|__PREFIX_MASTER__|${PREFIX_MASTER}|g" "$fullpath"
        sed -i "s|__PROJECTS_CONTAINER_MASTER__|${PROJECTS_CONTAINER_MASTER}|g" "$fullpath"
        sed -i "s|__PROJECT_ROOT__|${project_dir_basename}|g" "$fullpath"
        sed -i "s|__URI__|${uri}|g" "$fullpath"
        sed -i "s|__NEW_VERSION__|${NEW_VERSION}|g" "$fullpath"
        fileMustExists "$fullpath"
    fi
    ____

    link_symbolic "$fullpath" "$BINARY_DIRECTORY/cd-drupal-${filename}"
done

if [ -n "$mktemp" ];then
    rm "$mktemp"
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
# --project-parent-name
# --domain
# )
# MULTIVALUE=(
# )
# FLAG_VALUE=(
# )
# EOF
# clear
