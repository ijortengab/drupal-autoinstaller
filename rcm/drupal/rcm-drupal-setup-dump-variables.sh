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
    title RCM Drupal Setup Dump Variables
    _ 'Variation '; yellow Default; _.
    _ 'Version '; yellow `printVersion`; _.
    _.
    cat << 'EOF'
Usage: rcm-drupal-setup-dump-variables [options]

Options:
   --project-name *
        Set the project name. This should be in machine name format.
   --project-parent-name
        Set the project parent name. Value available from command: ls-drupal().
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
EOF
}

# Help and Version.
[ -n "$help" ] && { printHelp; exit 1; }
[ -n "$version" ] && { printVersion; exit 1; }

# Title.
title rcm-drupal-setup-dump-variables
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
databaseCredentialDrupal() {
    if [ -f "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential/database" ];then
        local DB_USER DB_USER_PASSWORD
        # Populate.
        . "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential/database"
        db_user=$DB_USER
        db_user_password=$DB_USER_PASSWORD
    fi
}
websiteCredentialDrupal() {
    if [ -f "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential/drupal/${drupal_fqdn_localhost}" ];then
        local ACCOUNT_NAME ACCOUNT_PASS
        . "${PREFIX_MASTER}/${PROJECTS_CONTAINER_MASTER}/${project_dir}/credential/drupal/${drupal_fqdn_localhost}"
        account_name=$ACCOUNT_NAME
        account_pass=$ACCOUNT_PASS
    fi
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
project_dir="$project_name"
drupal_fqdn_localhost="$project_name".drupal.localhost
[ -n "$project_parent_name" ] && {
    drupal_fqdn_localhost="$project_name"."$project_parent_name".drupal.localhost
    project_dir="$project_parent_name"
}
PREFIX_MASTER=${PREFIX_MASTER:=/usr/local/share/drupal}
code 'PREFIX_MASTER="'$PREFIX_MASTER'"'
PROJECTS_CONTAINER_MASTER=${PROJECTS_CONTAINER_MASTER:=projects}
code 'PROJECTS_CONTAINER_MASTER="'$PROJECTS_CONTAINER_MASTER'"'
____

if [ -n "$domain" ];then
    fqdn_string="$domain"
else
    fqdn_string="$drupal_fqdn_localhost"
fi

chapter Drupal "http://${fqdn_string}"
websiteCredentialDrupal
_ ' - 'username: $account_name; _.
_ '   'password: $account_pass; _.
____

list_host=("${drupal_fqdn_localhost}")
if [ -n "$domain" ];then
    list_host+=("${domain}.localhost")
fi
chapter Alias Hostname
for host in "${list_host[@]}";do
    _ ' - 'http://"$host"; _.
done
____

chapter Database Credential
databaseCredentialDrupal
_ ' - 'username: $db_user; _.
_ '   'password: $db_user_password; _.
____

list_uri=("${drupal_fqdn_localhost}")
if [ -n "$domain" ];then
    list_uri+=("${domain}")
    list_uri+=("${domain}.localhost")
fi

for uri in "${list_uri[@]}";do
    each="cd-drupal-${uri}"
    if [ -f "$BINARY_DIRECTORY/$each" ];then
        chapter The '`'drush'`' command for $uri
        code . "${each}"
        code drush status
        ____
    fi
done

chapter Manual Action
_ If you want to see the credentials again, please execute this command:; _.
[ -n "$project_parent_name" ] && has_project_parent_name=' --project-parent-name='"'${project_parent_name}'" || has_project_parent_name=''
[ -n "$domain" ] && has_domain=' --domain='"'${domain}'" || has_domain=''
__; magenta rcm drupal-setup-dump-variables${isfast} -- --project-name="'${project_name}'"${has_project_parent_name}${has_domain}; _.
_ It is recommended for you to level up file system directory outside web root, please execute this command:; _.
__; magenta rcm install drupal-adjust-file-system-outside-web-root --source drupal; _.
__; magenta rcm drupal-adjust-file-system-outside-web-root${isfast} -- --project-name="'${project_parent_name:-$project_name}'"; _.
_ There are helpful commands to browse all projects:; _.
__; magenta cd-drupal --help; _.
__; magenta ls-drupal --help; _.
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
