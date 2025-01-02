#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --fast) fast=1; shift ;;
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
    echo '0.11.15'
}
printHelp() {
    title RCM Drupal Setup Internal Command
    _ 'Variation '; yellow ls-drupal; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << 'EOF'
Usage: rcm-drupal-setup-internal-command-ls-drupal [options]

Options:

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
title rcm-drupal-setup-internal-command-ls-drupal
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
backupFile() {
    local mode="$1"
    local oldpath="$2" i newpath
    local target_dir="$3"
    i=1
    dirname=$(dirname "$oldpath")
    basename=$(basename "$oldpath")
    if [ -n "$target_dir" ];then
        case "$target_dir" in
            parent) dirname=$(dirname "$dirname") ;;
            *) dirname="$target_dir"
        esac
    fi
    [ -d "$dirname" ] || { echo 'Directory is not exists.' >&2; return 1; }
    newpath="${dirname}/${basename}.${i}"
    if [ -f "$newpath" ]; then
        let i++
        newpath="${dirname}/${basename}.${i}"
        while [ -f "$newpath" ] ; do
            let i++
            newpath="${dirname}/${basename}.${i}"
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
    # Trim trailing slash.
    oldpath=$(echo "$oldpath" | sed -E 's|/+$||g')
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
link_symbolic() {
    local source="$1"
    local target="$2"
    local sudo="$3"
    local source_mode="$4"
    local create
    [ "$sudo" == - ] && sudo=
    [ "$source_mode" == absolute ] || source_mode=
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
        if [ -z "$source_mode" ];then
            source=$(realpath -s --relative-to="$target_parent" "$source")
        fi
        if [ -n "$sudo" ];then
            code sudo -u '"'$sudo'"' ln -s '"'$source'"' '"'$target'"'
            sudo -u "$sudo" ln -s "$source" "$target"
        else
            code ln -s '"'$source'"' '"'$target'"'
            ln -s "$source" "$target"
        fi
        if [ $? -eq 0 ];then
            __; green Symbolic link berhasil dibuat.; _.
        else
            __; red Symbolic link gagal dibuat.; x
        fi
    fi
    ____
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

# Requirement, validate, and populate value.
chapter Dump variable.
delay=.5; [ -n "$fast" ] && unset delay
__FILE__=$(resolve_relative_path "$0")
__DIR__=$(dirname "$__FILE__")
BINARY_DIRECTORY=${BINARY_DIRECTORY:=$__DIR__}
code 'BINARY_DIRECTORY="'$BINARY_DIRECTORY'"'
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

chapter Mengecek '`'ls-drupal'`' command.
fullpath="${PREFIX_MASTER}/${BINARY_MASTER}/ls-drupal"
dirname="${PREFIX_MASTER}/${BINARY_MASTER}"
isFileExists "$fullpath"
____

if [ -n "$found" ];then
    chapter Mengecek versi '`'ls-drupal'`' command.
    code ls-drupal --version
    if [ -z "$mktemp" ];then
        mktemp=$(mktemp -p /dev/shm)
    fi
    "$fullpath" --version 2>/dev/null > $mktemp
    while read line; do e "$line"; _.; done < $mktemp
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
    ____
fi

if [ -n "$notfound" ];then
    chapter Create Drupal Command '`'ls-drupal'`'.
    mkdir -p "$dirname"
    touch "$fullpath"
    chmod a+x "$fullpath"
    cat << 'EOF' > "$fullpath"
#!/bin/bash
[[ -f "$0" && ! "$0" == $(command -v bash) ]] || {
    echo -e "\e[91m""Invalid execution: "'`'. ls-drupal'`'"\e[39m". Try this one: '`'ls-drupal'`'.
    return
}
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
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
printHelp() {
    cat << 'EOL'
Usage: ls-drupal
       ls-drupal [options]
       ls-drupal [project]
       ls-drupal -

       List the domain by [project].
       If [project] omitted, it will list the project name.
       Set [project] with - (dash), it will list all domain.

Options:
   --version
        Print version of this script.
   --help
        Show this help.
EOL
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

PREFIX_MASTER=__PREFIX_MASTER__
PROJECTS_CONTAINER_MASTER=__PROJECTS_CONTAINER_MASTER__
SITES_MASTER=__SITES_MASTER__
project_name="$1"; shift
if [ -z "$project_name" ];then
    ls "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}"
else
    case "$project_name" in
        -)
            while read line; do
                ls "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${line}/${SITES_MASTER}"
            done <<< `ls "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}"`
            ;;
        *)
            ls "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_name}/${SITES_MASTER}"
    esac
fi
EOF
    sed -i "s|__PREFIX_MASTER__|${PREFIX_MASTER}|g" "$fullpath"
    sed -i "s|__PROJECTS_CONTAINER_MASTER__|${PROJECTS_CONTAINER_MASTER}|g" "$fullpath"
    sed -i "s|__SITES_MASTER__|${SITES_MASTER}|g" "$fullpath"
    sed -i "s|__NEW_VERSION__|${NEW_VERSION}|g" "$fullpath"
    fileMustExists "$fullpath"
    ____
fi

link_symbolic "$fullpath" "$BINARY_DIRECTORY/ls-drupal"

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
# )
# FLAG_VALUE=(
# )
# EOF
# clear
