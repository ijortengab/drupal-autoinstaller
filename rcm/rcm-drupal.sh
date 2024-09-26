#!/bin/bash

# Parse arguments. Generated by parse-options.sh.
_new_arguments=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) help=1; shift ;;
        --version) version=1; shift ;;
        --fast) fast=1; shift ;;
        --non-interactive) non_interactive=1; shift ;;
        --root-sure) root_sure=1; shift ;;
        --variation=*) variation="${1#*=}"; shift ;;
        --variation) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then variation="$2"; shift; fi; shift ;;
        --) shift
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

# Command.
command="$1"; shift
if [ -n "$command" ];then
    case "$command" in
        eligible) ;;
        # Bring back command as argument position.
        *) set -- "$command" "$@"
    esac
fi

# Functions.
printVersion() {
    echo '0.11.2'
}
printHelp() {
    title Drupal Auto-Installer
    _ 'Homepage '; yellow https://github.com/ijortengab/drupal-autoinstaller; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << EOF
Usage: rcm-drupal [command] [options]

Options:
   --variation *
        Select the variation setup. Values available from command: rcm-drupal(eligible).

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
   rcm-drupal-setup-variation-default:`printVersion`
   rcm-drupal-setup-variation-lemp-stack:`printVersion`

Download:
   [rcm-drupal-setup-variation-default](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-variation-default.sh)
   [rcm-drupal-setup-variation-lemp-stack](https://github.com/ijortengab/drupal-autoinstaller/raw/master/rcm/drupal/rcm-drupal-setup-variation-lemp-stack.sh)
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Dependency.
while IFS= read -r line; do
    [[ -z "$line" ]] || command -v `cut -d: -f1 <<< "${line}"` >/dev/null || { echo -e "\e[91m""Unable to proceed, "'`'"${line}"'`'" command not found." "\e[39m"; exit 1; }
done <<< `printHelp 2>/dev/null | sed -n '/^Dependency:/,$p' | sed -n '2,/^\s*$/p' | sed 's/^ *//g'`

# Functions.
eligible() {
    # chapter Available:
    eligible=()
    if [ -f /etc/os-release ];then
        . /etc/os-release
    fi
    _; _.
    __; _, 'Variation  '; green 0; _, . Just Drupal without LEMP Stack setup. ; _.; eligible+=("0;all;all")
    __; _, 'Variation  '; [[ "$ID" == debian && "$VERSION_ID" == 11 ]] && color=green || color=red; $color 1; _, . Debian 11, '   'PHP 8.2, Drupal 10, Drush 12.; _.; eligible+=("1;debian;11")
    __; _, 'Variation  '; [[ "$ID" == debian && "$VERSION_ID" == 11 ]] && color=green || color=red; $color 2; _, . Debian 11, '   'PHP 8.1, Drupal ' '9, Drush 11. ; _.; eligible+=("2;debian;11")
    __; _, 'Variation  '; [[ "$ID" == ubuntu && "$VERSION_ID" == 22.04 ]] && color=green || color=red; $color 3; _, . Ubuntu 22.04, PHP 8.2, Drupal 10, Drush 12. ; _.; eligible+=("3;ubuntu;22.04")
    __; _, 'Variation  '; [[ "$ID" == ubuntu && "$VERSION_ID" == 22.04 ]] && color=green || color=red; $color 4; _, . Ubuntu 22.04, PHP 8.1, Drupal ' '9, Drush 11. ; _.; eligible+=("4;ubuntu;22.04")
    __; _, 'Variation  '; [[ "$ID" == debian && "$VERSION_ID" == 12 ]] && color=green || color=red; $color 5; _, . Debian 12, '   'PHP 8.2, Drupal 10, Drush 12. ; _.; eligible+=("5;debian;12")
    __; _, 'Variation  '; [[ "$ID" == debian && "$VERSION_ID" == 12 ]] && color=green || color=red; $color 6; _, . Debian 12, '   'PHP 8.1, Drupal ' '9, Drush 11. ; _.; eligible+=("6;debian;12")
    __; _, 'Variation  '; [[ "$ID" == debian && "$VERSION_ID" == 12 ]] && color=green || color=red; $color 7; _, . Debian 12, '   'PHP 8.3, Drupal 10, Drush 12. ; _.; eligible+=("7;debian;12")
    __; _, 'Variation  '; [[ "$ID" == debian && "$VERSION_ID" == 11 ]] && color=green || color=red; $color 8; _, . Debian 11, '   'PHP 8.3, Drupal 10, Drush 12. ; _.; eligible+=("8;debian;11")
    __; _, 'Variation  '; [[ "$ID" == ubuntu && "$VERSION_ID" == 22.04 ]] && color=green || color=red; $color 9; _, . Ubuntu 22.04, PHP 8.3, Drupal 10, Drush 12. ; _.; eligible+=("9;ubuntu;22.04")
    __; _, 'Variation '; [[ "$ID" == ubuntu && "$VERSION_ID" == 22.04 ]] && color=green || color=red; $color 10; _, . Ubuntu 22.04, PHP 8.3, Drupal 11, Drush 13. ; _.; eligible+=("10;ubuntu;22.04")
    __; _, 'Variation '; [[ "$ID" == debian && "$VERSION_ID" == 12 ]] && color=green || color=red; $color 11; _, . Debian 12, '   'PHP 8.3, Drupal 11, Drush 13. ; _.; eligible+=("11;debian;12")
    __; _, 'Variation '; [[ "$ID" == ubuntu && "$VERSION_ID" == 24.04 ]] && color=green || color=red; $color 12; _, . Ubuntu 24.04, PHP 8.3, Drupal 11, Drush 13. ; _.; eligible+=("12;ubuntu;24.04")
    for each in "${eligible[@]}";do
        variation=$(cut -d';' -f1 <<< "$each")
        _id=$(cut -d';' -f2 <<< "$each")
        _version_id=$(cut -d';' -f3 <<< "$each")
        if [[ "$_id" == "all" && "$_version_id" == "all" ]];then
            echo $variation
        elif [[ "$_id" == "$ID" && "$_version_id" == "$VERSION_ID" ]];then
            echo $variation
        fi
    done
}

# Execute command.
if [[ $command == eligible ]];then
    eligible
    exit 0
fi

# Title.
title rcm-drupal
____

# Require, validate, and populate value.
chapter Dump variable.
delay=.5; [ -n "$fast" ] && unset delay
[ -n "$fast" ] && isfast=' --fast' || isfast=''
[ -n "$non_interactive" ] && isnoninteractive=' --non-interactive' || isnoninteractive=''
if [ -z "$variation" ];then
    error "Argument --variation required."; x
fi
code 'variation="'$variation'"'
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

case "$variation" in
    0) rcm_operand=drupal-setup-variation-default ;;
    *) rcm_operand=drupal-setup-variation-lemp-stack ;;
esac

chapter Execute:

case "$rcm_operand" in
    drupal-setup-variation-default)
        code rcm${isfast}${isnoninteractive} $rcm_operand -- "$@"
        ____

        INDENT+="    " BINARY_DIRECTORY="$BINARY_DIRECTORY" rcm${isfast}${isnoninteractive} $rcm_operand --root-sure --binary-directory-exists-sure -- "$@"
        ;;
    drupal-setup-variation-lemp-stack)
        code rcm${isfast}${isnoninteractive} $rcm_operand -- --variation="$variation" "$@"
        ____

        INDENT+="    " BINARY_DIRECTORY="$BINARY_DIRECTORY" rcm${isfast}${isnoninteractive} $rcm_operand --root-sure --binary-directory-exists-sure -- --variation="$variation" "$@"
esac
____

exit 0

# parse-options.sh \
# --without-end-options-double-dash \
# --compact \
# --clean \
# --no-hash-bang \
# --no-original-arguments \
# --no-error-invalid-options \
# --with-end-options-double-dash \
# --no-error-require-arguments << EOF | clip
# FLAG=(
# --fast
# --version
# --help
# --root-sure
# --non-interactive
# )
# VALUE=(
# --variation
# )
# MULTIVALUE=(
# )
# FLAG_VALUE=(
# )
# EOF
# clear
