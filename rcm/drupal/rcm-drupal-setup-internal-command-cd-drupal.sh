#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --fast) fast=1; shift ;;
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
__() { echo -n "$INDENT" >&2; echo -n "#" '    ' >&2; [ -n "$1" ] && echo "$@" >&2; }
____() { echo >&2; [ -n "$RCM_DELAY" ] && sleep "$RCM_DELAY"; }

# Define variables and constants.
RCM_DELAY=${RCM_DELAY:=.5}; [ -n "$fast" ] && unset RCM_DELAY
DRUPAL_PREFIX=${DRUPAL_PREFIX:=/usr/local/share/drupal}
DRUPAL_PROJECTS_DIRNAME=${DRUPAL_PROJECTS_DIRNAME:=projects}
DRUPAL_USERS_DIRNAME=${DRUPAL_USERS_DIRNAME:=users}
DRUPAL_BINARY_DIRNAME=${DRUPAL_BINARY_DIRNAME:=bin}
DRUPAL_SITES_DIRNAME=${DRUPAL_SITES_DIRNAME:=sites}
BINARY_DIRECTORY=${BINARY_DIRECTORY:=[__DIR__]}

# Functions.
printVersion() {
    echo '0.11.17'
}
printHelp() {
    title RCM Drupal Setup Internal Command
    _ 'Variation '; yellow cd-drupal; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-drupal-setup-internal-command-cd-drupal [options]

Options:

Global Options:
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.

Environment Variables:
   BINARY_DIRECTORY
        Default to $BINARY_DIRECTORY
   DRUPAL_PREFIX
        Default to $DRUPAL_PREFIX
   DRUPAL_PROJECTS_DIRNAME
        Default to $DRUPAL_PROJECTS_DIRNAME
   DRUPAL_USERS_DIRNAME
        Default to $DRUPAL_USERS_DIRNAME
   DRUPAL_SITES_DIRNAME
        Default to $DRUPAL_SITES_DIRNAME
   DRUPAL_BINARY_DIRNAME
        Default to $DRUPAL_BINARY_DIRNAME
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-drupal-setup-internal-command-cd-drupal
____

[ "$EUID" -ne 0 ] && { error This script needs to be run with superuser privileges.; x; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { error Unable to proceed, command not found: '`'`cut -d: -f1 <<< "${line}"`'`'.; x; }
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
__FILE__=$(resolve_relative_path "$0")
__DIR__=$(dirname "$__FILE__")
code 'BINARY_DIRECTORY="'$BINARY_DIRECTORY'"'
find='[__DIR__]'
replace="$__DIR__"
BINARY_DIRECTORY="${BINARY_DIRECTORY/"$find"/"$replace"}"
code 'BINARY_DIRECTORY="'$BINARY_DIRECTORY'"'
code 'DRUPAL_PREFIX="'$DRUPAL_PREFIX'"'
code 'DRUPAL_PROJECTS_DIRNAME="'$DRUPAL_PROJECTS_DIRNAME'"'
code 'DRUPAL_BINARY_DIRNAME="'$DRUPAL_BINARY_DIRNAME'"'
code 'DRUPAL_SITES_DIRNAME="'$DRUPAL_SITES_DIRNAME'"'
print_version=`printVersion`
code 'print_version="'$print_version'"'
mktemp=
____

chapter Mengecek '`'cd-drupal'`' command.
fullpath="${DRUPAL_PREFIX}/${DRUPAL_BINARY_DIRNAME}/cd-drupal"
dirname="${DRUPAL_PREFIX}/${DRUPAL_BINARY_DIRNAME}"
isFileExists "$fullpath"
____

if [ -n "$found" ];then
    chapter Mengecek versi '`'cd-drupal'`' command.
    code cd-drupal --version
    if [ -z "$mktemp" ];then
        mktemp=$(mktemp -p /dev/shm)
    fi
    "$fullpath" --version 2>/dev/null > $mktemp
    while read line; do e "$line"; _.; done < $mktemp
    old_version=$(head -1 $mktemp)
    if [[ "$old_version" =~ [^0-9\.]+ ]];then
        old_version=0
    fi
    vercomp $print_version $old_version
    if [[ $? -eq 1 ]];then
        __ Command perlu diupdate. Versi saat ini ${print_version}.
        found=
        notfound=1
    else
        __ Command tidak perlu diupdate. Versi saat ini ${print_version}.
    fi
    ____
fi

if [ -n "$notfound" ];then
    chapter Create Drupal Command '`'cd-drupal'`'.
    mkdir -p "$dirname"
    touch "$fullpath"
    chmod a+x "$fullpath"
    cat << 'EOF' > "$fullpath"
#!/bin/bash
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
    echo '__CURRENT_VERSION__'
}
printHelp() {
    cat << 'EOL'
Usage: . cd-drupal

       Change the shell working directory to Drupal Project, set and export some
       environment variable about Drupal, and set drush alias.

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

[[ -f "$0" && ! "$0" == $(command -v bash) ]] && { echo -e "\e[91m""Usage: . "$(basename "$0") "\e[39m"; exit 1; }
DRUPAL_PREFIX=__DRUPAL_PREFIX__
DRUPAL_PROJECTS_DIRNAME=__DRUPAL_PROJECTS_DIRNAME__
DRUPAL_USERS_DIRNAME=__DRUPAL_USERS_DIRNAME__
DRUPAL_SITES_DIRNAME=__DRUPAL_SITES_DIRNAME__
whoami=`whoami`
source=()
[ "$EUID" -eq 0 ] && path="${DRUPAL_PREFIX}/${DRUPAL_PROJECTS_DIRNAME}" || \
    path="${DRUPAL_PREFIX}/${DRUPAL_USERS_DIRNAME}/${whoami}/projects"
[ ! -d "$path" ] && {
    echo -e "\e[91m""There's no Drupal Directory Project: ${path}" "\e[39m";
} || {
    source=(`ls "$path"`)
}
[ "${#source[@]}" -eq 0 ] && echo -e There are no Drupal project available. || {
    echo -e There are Drupal project available. Press the "\e[93m"yellow"\e[39m" number key to select.
    declare -i count
    count=0
    for each in "${source[@]}";do
        count+=1
        if [ $count -lt 10 ];then
            echo -ne '['"\e[93m"$count"\e[39m"']' "$each" "\n"
        else
            echo '['$count']' "$each"
        fi
    done
    echo -ne '['"\e[93m"Enter"\e[39m"']' "\e[93m"T"\e[39m"ype the number key instead. "\n"
    count_max="${#source[@]}"
    if [ $count_max -gt 9 ];then
        count_max=9
    fi
    project_dir=
    while true; do
        read -rsn 1 -p "Select: " char;
        if [ -z "$char" ];then
            char=t
        fi
        case $char in
            t|T) echo "$char"; break ;;
            [1-$count_max])
                echo "$char"
                i=$((char - 1))
                project_dir="${source[$i]}"
                break ;;
            *) echo
        esac
    done
    until [ -n "$project_dir" ];do
        read -p "Type the value: " project_dir
        if [[ $project_dir =~ [^0-9] ]];then
            project_dir=
        fi
        if [ -n "$project_dir" ];then
            project_dir=$((project_dir - 1))
            project_dir="${source[$project_dir]}"
        fi
    done
    echo -e Project "\e[93m""$project_dir""\e[39m" selected.
    echo
    unset count
    declare -i count
    count=0
    source=()
    while read line; do
        if [ "${#source[@]}" -eq 0 ];then
            echo -e There are Site available. Press the "\e[93m"yellow"\e[39m" number key to select.
        fi
        count+=1
        line_url=$("${DRUPAL_PREFIX}/${DRUPAL_PROJECTS_DIRNAME}/${project_dir}/${DRUPAL_SITES_DIRNAME}/${line}" --url)
        if [ $count -lt 10 ];then
            echo -ne '['"\e[93m"$count"\e[39m"']' "$line_url" "\n"
        else
            echo '['$count']' "$line_url"
        fi
        source+=("$line")
    done <<< `ls "${DRUPAL_PREFIX}/${DRUPAL_PROJECTS_DIRNAME}/${project_dir}/${DRUPAL_SITES_DIRNAME}"`
    count_max="${#source[@]}"
    if [ $count_max -gt 9 ];then
        count_max=9
    fi
    if [ "${#source[@]}" -eq 0 ];then
        echo -e There are no site available.
    else
        echo -ne '['"\e[93m"Enter"\e[39m"']' "\e[93m"T"\e[39m"ype the number key instead. "\n"
        value=
        while true; do
            read -rsn 1 -p "Select: " char;
            if [ -z "$char" ];then
                char=t
            fi
            case $char in
                t|T) echo "$char"; break ;;
                [1-$count_max])
                    echo "$char"
                    i=$((char - 1))
                    value="${source[$i]}"
                    break ;;
                *) echo
            esac
        done
        until [ -n "$value" ];do
            read -p "Type the value: " value
            if [[ $value =~ [^0-9] ]];then
                value=
            fi
            if [ -n "$value" ];then
                value=$((value - 1))
                value="${source[$value]}"
            fi
        done
        value_url=$("${DRUPAL_PREFIX}/${DRUPAL_PROJECTS_DIRNAME}/${project_dir}/${DRUPAL_SITES_DIRNAME}/${value}" --url)
        echo -e Site "\e[93m""$value_url""\e[39m" selected.
    fi
    echo
    echo -e We will execute: "\e[95m". cd-drupal-${value}"\e[39m"
    echo -ne '['"\e[93m"Esc"\e[39m"']' "\e[93m"Q"\e[39m"uit. "\n"
    echo -ne '['"\e[93m"Enter"\e[39m"']' Continue. "\n"
    exe=
    while true; do
        read -rsn 1 -p "Select: " char;
        if [ -z "$char" ];then
            printf "\r\033[K" >&2
            exe=1
            break
        fi
        case $char in
            $'\33') echo "q"; break ;;
            q|Q) echo "$char"; break ;;
            *) echo
        esac
    done
    if [ -n "$exe" ];then
        echo
        echo -e "\e[95m". cd-drupal-${value}"\e[39m"
        . cd-drupal-${value}
    fi
}
EOF
    sed -i "s|__DRUPAL_PREFIX__|${DRUPAL_PREFIX}|g" "$fullpath"
    sed -i "s|__DRUPAL_PROJECTS_DIRNAME__|${DRUPAL_PROJECTS_DIRNAME}|g" "$fullpath"
    sed -i "s|__DRUPAL_USERS_DIRNAME__|${DRUPAL_USERS_DIRNAME}|g" "$fullpath"
    sed -i "s|__DRUPAL_SITES_DIRNAME__|${DRUPAL_SITES_DIRNAME}|g" "$fullpath"
    sed -i "s|__CURRENT_VERSION__|${print_version}|g" "$fullpath"
    fileMustExists "$fullpath"
    ____
fi

link_symbolic "$fullpath" "$BINARY_DIRECTORY/cd-drupal"

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
# )
# VALUE=(
# )
# FLAG_VALUE=(
# )
# EOF
# clear
