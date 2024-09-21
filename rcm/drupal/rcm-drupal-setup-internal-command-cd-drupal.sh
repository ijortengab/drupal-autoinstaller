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
e() { echo -n "$INDENT" >&2; echo "#" "$@" >&2; }
_() { echo -n "$INDENT" >&2; echo -n "#" "$@" >&2; }
_,() { echo -n "$@" >&2; }
_.() { echo >&2; }
__() { echo -n "$INDENT" >&2; echo -n "#" '    ' >&2; [ -n "$1" ] && echo "$@" >&2 || echo -n  >&2; }
____() { echo >&2; [ -n "$delay" ] && sleep "$delay"; }

# Functions.
printVersion() {
    echo '0.9.0'
}
printHelp() {
    title RCM Drupal Setup Internal Command
    _ 'Variation '; yellow cd-drupal; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << 'EOF'
Usage: rcm-drupal-setup-internal-command-cd-drupal [options]

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

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v "${line}" >/dev/null || { echo -e "\e[91m""Unable to proceed, "'`'"${line}"'`'" command not found." "\e[39m"; exit 1; }
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
    local create
    _success=
    [ -e "$source" ] || { error Source not exist: $source.; x; }
    [ -n "$target" ] || { error Target not defined.; x; }
    [[ $(type -t backupFile) == function ]] || { error Function backupFile not found.; x; }

    chapter Membuat symbolic link.
    __ source: '`'$source'`'
    __ target: '`'$target'`'
    if [ -h "$target" ];then
        __ Path target saat ini sudah merupakan symbolic link: '`'$target'`'
        __; _, Mengecek apakah link merujuk ke '`'$source'`':
        _dereference=$(stat ${stat_cached} "$target" -c %N)
        match="'$target' -> '$source'"
        if [[ "$_dereference" == "$match" ]];then
            _, ' 'Merujuk.; _.
        else
            _, ' 'Tidak merujuk.; _.
            __ Melakukan backup.
            backupFile move "$target"
            create=1
        fi
    elif [ -e "$target" ];then
        __ File/directory bukan merupakan symbolic link.
        __ Melakukan backup.
        backupFile move "$target"
        create=1
    else
        create=1
    fi
    if [ -n "$create" ];then
        __ Membuat symbolic link '`'$target'`'.
        if [ -n "$sudo" ];then
            __; magenta sudo -u '"'$sudo'"' ln -s '"'$source'"' '"'$target'"'; _.
            sudo -u "$sudo" ln -s "$source" "$target"
        else
            __; magenta ln -s '"'$source'"' '"'$target'"'; _.
            ln -s "$source" "$target"
        fi
        __ Verifikasi
        if [ -h "$target" ];then
            _dereference=$(stat ${stat_cached} "$target" -c %N)
            match="'$target' -> '$source'"
            if [[ "$_dereference" == "$match" ]];then
                __; green Symbolic link berhasil dibuat.; _.
                _success=1
            else
                __; red Symbolic link gagal dibuat.; x
            fi
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

# Title.
title rcm-drupal-setup-internal-command-cd-drupal
____

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
mktemp=
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

chapter Mengecek '`'cd-drupal'`' command.
fullpath="${PREFIX_MASTER}/${BINARY_MASTER}/cd-drupal"
dirname="${PREFIX_MASTER}/${BINARY_MASTER}"
isFileExists "$fullpath"
____

if [ -n "$found" ];then
    chapter Mengecek versi '`'cd-drupal'`' command.
    code cd-drupal --version
    if [ -z "$mktemp" ];then
        mktemp=$(mktemp -p /dev/shm)
    fi
    "$fullpath" --version | tee $mktemp
    old_version=$(head -1 $mktemp)
    if [[ "$old_version" =~ [^0-9\.]+ ]];then
        old_version=0
    fi
    NEW_VERSION=`printVersion`
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
    echo '__NEW_VERSION__'
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
PREFIX_MASTER=__PREFIX_MASTER__
PROJECTS_CONTAINER_MASTER=__PROJECTS_CONTAINER_MASTER__
SITES_MASTER=__SITES_MASTER__
[[ ! -d "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}" ]] && { echo -e "\e[91m""There's no Drupal Directory Master : ${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}" "\e[39m"; }
if [[ -d "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}" ]];then
    echo -e There are Drupal project available. Press the "\e[93m"yellow"\e[39m" number key to select.
    unset count
    declare -i count
    count=0
    source=()
    while read line; do
        basename=$(basename "$line")
        count+=1
        if [ $count -lt 10 ];then
            echo -ne '['"\e[93m"$count"\e[39m"']' "$basename" "\n"
        else
            echo '['$count']' "$basename"
        fi
        source+=("$basename")
    done <<< `ls "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}"`
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
        if [ $count -lt 10 ];then
            echo -ne '['"\e[93m"$count"\e[39m"']' "$line" "\n"
        else
            echo '['$count']' "$line"
        fi
        source+=("$line")
    done <<< `ls "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/${SITES_MASTER}"`
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
        echo -e Site "\e[93m""$value""\e[39m" selected.
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
fi
EOF
    sed -i "s|__PREFIX_MASTER__|${PREFIX_MASTER}|g" "$fullpath"
    sed -i "s|__PROJECTS_CONTAINER_MASTER__|${PROJECTS_CONTAINER_MASTER}|g" "$fullpath"
    sed -i "s|__SITES_MASTER__|${SITES_MASTER}|g" "$fullpath"
    sed -i "s|__NEW_VERSION__|${NEW_VERSION}|g" "$fullpath"
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
# --root-sure
# )
# VALUE=(
# )
# FLAG_VALUE=(
# )
# EOF
# clear
