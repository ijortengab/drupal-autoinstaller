#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
_n=
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --fast) fast=1; shift ;;
        --mode=*) mode="${1#*=}"; shift ;;
        --mode) if [[ ! $2 == "" && ! $2 =~ (^--$|^-[^-]|^--[^-]) ]]; then mode="$2"; shift; fi; shift ;;
        --non-interactive) non_interactive=1; shift ;;
        --root-sure) root_sure=1; shift ;;
        --verbose|-v) verbose="$((verbose+1))"; shift ;;
        --)
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    *) _new_arguments+=("$1"); shift ;;
                esac
            done
            ;;
        --[^-]*) shift ;;
        *) _new_arguments+=("$1"); shift ;;
    esac
done
set -- "${_new_arguments[@]}"
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -[^-]*) OPTIND=1
            while getopts ":v" opt; do
                case $opt in
                    v) verbose="$((verbose+1))" ;;
                esac
            done
            _n="$((OPTIND-1))"
            _n=${!_n}
            shift "$((OPTIND-1))"
            if [[ "$_n" == '--' ]];then
                while [[ $# -gt 0 ]]; do
                    case "$1" in
                        *) _new_arguments+=("$1"); shift ;;
                    esac
                done
            fi
            ;;
        --) shift
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    *) _new_arguments+=("$1"); shift ;;
                esac
            done
            ;;
        *) _new_arguments+=("$1"); shift ;;
    esac
done
set -- "${_new_arguments[@]}"
unset _new_arguments
unset _n

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

# Command.
command="$1"; shift
if [ -n "$command" ];then
    case "$command" in
        mode-available) ;;
        *)
            # Bring back command as argument position.
            set -- "$command" "$@"
            # Reset command.
            command=
    esac
fi

# Functions.
printVersion() {
    echo '0.11.15'
}
printHelp() {
    title Drupal Auto-Installer
    _ 'Homepage '; yellow https://github.com/ijortengab/drupal-autoinstaller; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-drupal [command] [options]

Options:
   --mode *
        Select the setup mode. Values available from command: rcm-drupal(mode-available).

Global Options.
   --fast
        No delay every subtask.
   --version
        Print version of this script.
   --help
        Show this help.
   --root-sure
        Bypass root checking.
   --non-interactive
        Skip prompt for every options.
   --
        Every arguments after double dash will pass to rcm-drupal-setup-variation-* command.

Dependency:
   rcm:0.16.2

Download:
   [rcm-drupal-setup-variation-default](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-variation-default.sh)
   [rcm-drupal-setup-variation-lemp-stack](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-variation-lemp-stack.sh)
   [rcm-drupal-setup-variation-multisite](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-variation-multisite.sh)
   [rcm-drupal-setup-variation-bundle](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-variation-bundle.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

ArraySearch() {
    local index match="$1"
    local source=("${!2}")
    for index in "${!source[@]}"; do
       if [[ "${source[$index]}" == "${match}" ]]; then
           _return=$index; return 0
       fi
    done
    return 1
}

# Functions.
mode-available() {
    command_required=(nginx mysql php)
    command_notfound=
    for each in "${command_required[@]}"; do
        if ! command -v $each >/dev/null;then
            command_notfound+=" $each"
        fi
    done

    if [ -n "$command_notfound" ];then
        mode_available+=(init)
    else
        mode_available+=(new)
        mode_available+=(custom)
        if command -v ls-drupal >/dev/null;then
            if [[ $(ls-drupal | wc -l) -gt 0 ]];then
                mode_available+=(multisite)
            fi
        fi
    fi
    _; _.
    if ArraySearch init mode_available[@] ]];then color=green; else color=red; fi
    __; _, 'Mode '; $color init; _, '       ' LEMP Stack Setup + Create a new project '(bundle)'. ; _.
    __; _, '                 '; _, 'Linux, (e)Nginx, MySQL/MariaDB, PHP'.; _.;
    if ArraySearch new mode_available[@] ]];then color=green; else color=red; fi
    __; _, 'Mode '; $color new; _, '        ' Create a new project '(bundle)'. ; _.
    if ArraySearch custom mode_available[@] ]];then color=green; else color=red; fi
    __; _, 'Mode '; $color custom; _, '     ' Create a new project '(custom)'. ; _.
    if ArraySearch multisite mode_available[@] ]];then color=green; else color=red; fi
    __; _, 'Mode '; $color multisite; _, '  ' Add sub project from exisiting project. ; _.
    __; _, '                 '; _, Drupal Multisite.; _.;
    for each in init new custom multisite; do
        if ArraySearch $each mode_available[@] ]];then echo $each; fi
    done
}

# Execute command.
if [[ -n "$command" && $(type -t "$command") == function ]];then
    "$command"
    exit 0
fi

# Title.
title rcm-drupal
____

wordWrapCommand() {
    # global words_array
    local inline_description="$1"
    local current_line first_line
    declare -i min; min=80
    declare -i max; max=100
    declare -i i; i=0
    local count="${#words_array[@]}"
    current_line=
    first_line=1
    for each in "${words_array[@]}"; do
        i+=1
        [ "$i" == "$count" ] && last=1 || last=
        if [ -z "$current_line" ]; then
            if [ -z "$first_line" ];then
                current_line="    ${each}"
                e; magenta "    $each";
            else
                first_line=
                if [ -n "$inline_description" ];then
                    e; _, "${inline_description} "; magenta "$each"
                    current_line="${inline_description} ${each}"
                else
                    e; magenta "$each"
                    current_line="$each"
                fi
            fi
            if [ -n "$last" ];then
                _.
            fi
        else
            _current_line="${current_line} ${each}"
            if [ "${#_current_line}" -le $min ];then
                if [ -n "$last" ];then
                    _, ' '; magenta "$each"; _.
                else
                    _, ' '; magenta "$each"
                fi
                current_line+=" ${each}"
            elif [ "${#_current_line}" -le $max ];then
                if [ -n "$last" ];then
                    _, ' '; magenta "${each}"''; _.
                else
                    _, ' '; magenta "${each}"' \'; _.
                fi
                current_line=
            else
                magenta ' \'; _.; e; magenta "    $each"
                current_line="    ${each}"
                if [ -n "$last" ];then
                    _.
                fi
            fi
        fi
    done
}

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

# Require, validate, and populate value.
chapter Dump variable.
delay=.5; [ -n "$fast" ] && unset delay
[ -n "$fast" ] && isfast=' --fast' || isfast=''
[ -n "$non_interactive" ] && isnoninteractive=' --non-interactive' || isnoninteractive=''
[ -n "$verbose" ] && {
    for ((i = 0 ; i < "$verbose" ; i++)); do
        isverbose+=' --verbose'
    done
} || isverbose=

if [ -n "$mode" ];then
    case "$mode" in
        init|new|custom|multisite) ;;
        *) error "Argument --mode not valid."; x ;;
    esac
fi
if [ -z "$mode" ];then
    error "Argument --mode required."; x
fi
code 'mode="'$mode'"'
____

case "$mode" in
    init) rcm_operand=drupal-setup-variation-lemp-stack ;;
    new) rcm_operand=drupal-setup-variation-bundle ;;
    custom) rcm_operand=drupal-setup-variation-default ;;
    multisite) rcm_operand=drupal-setup-variation-multisite ;;
    *) error "Argument --mode not valid."; x ;;
esac

chapter Execute:

case "$rcm_operand" in
    *)
        words_array=(rcm${isfast}${isnoninteractive}${isverbose} $rcm_operand -- "$@")
        wordWrapCommand
        ____

        INDENT+="    " BINARY_DIRECTORY="$BINARY_DIRECTORY" rcm${isfast}${isnoninteractive}${isverbose} $rcm_operand --root-sure --binary-directory-exists-sure --non-immediately -- "$@"
        ;;
esac
____

exit 0

# parse-options.sh \
# --compact \
# --clean \
# --no-hash-bang \
# --no-original-arguments \
# --no-error-invalid-options \
# --no-error-require-arguments << EOF | clip
# INCREMENT=(
    # '--verbose|-v'
# )
# FLAG=(
# --fast
# --version
# --help
# --root-sure
# --non-interactive
# )
# VALUE=(
# --mode
# )
# MULTIVALUE=(
# )
# FLAG_VALUE=(
# )
# EOF
# clear
