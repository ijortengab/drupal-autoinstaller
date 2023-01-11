#!/bin/bash
# @filename: gpl-drupal-variation1.sh
# variation 1: drupal latest on ubuntu 22.04.

while [[ $# -gt 0 ]]; do
    case "$1" in
        --domain=*) domain+=("${1#*=}"); shift ;;
        --domain) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then domain+=("$2"); shift; fi; shift ;;
        --domain-strict) domain_strict=1; shift ;;
        --project-name=*) project_name="${1#*=}"; shift ;;
        --project-name) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then project_name="$2"; shift; fi; shift ;;
        --project-parent-name=*) project_parent_name="${1#*=}"; shift ;;
        --project-parent-name) if [[ ! $2 == "" && ! $2 =~ ^-[^-] ]]; then project_parent_name="$2"; shift; fi; shift ;;
        --[^-]*) shift ;;
        *) shift ;;
    esac
done

[ -n "$project_name" ] || { echo "Options --project-name required."; exit 1; }
[[ $project_name = *" "* ]] && { echo "Options --project-name can not contain space."; exit 1; }
project_name_safe_value=$(sed -E 's|[^a-zA-Z0-9]|_|g' <<< "$project_name" | sed -E 's|_+|_|g' )
if [[ ! $project_name == $project_name_safe_value ]];then
    echo "The value of --project-name can only contain alphanumeric and underscores."
    echo "Suggest: --project-name="$project_name_safe_value
    exit
fi
[ -n "$project_parent_name" ] && {
    [[ $project_parent_name = *" "* ]] && { echo "Options --project-parnet-name can not contain space."; exit 1; }
    project_parent_name_safe_value=$(sed -E 's|[^a-zA-Z0-9]|_|g' <<< "$project_parent_name" | sed -E 's|_+|_|g' )
    if [[ ! $project_parent_name == $project_parent_name_safe_value ]];then
        echo "The value of --project-parent-name can only contain alphanumeric and underscores."
        echo "Suggest: --project-parent-name="$project_parent_name_safe_value
        exit
    fi
}

DB_USER_HOST=localhost
project_dir=$project_name
nginx_config_file=$project_name
subdomain_localhost="${project_name}.localhost"
[ -n "$project_parent_name" ] && {
    project_dir=$project_parent_name
    nginx_config_file=$project_parent_name
    subdomain_localhost="${project_name}.${project_parent_name}.localhost"
}
db_name="${project_name}_drupal"
sites_subdir=$project_name
[ -n "$project_parent_name" ] && {
    db_name="${project_parent_name}__${project_name}"_drupal
    sites_subdir="${project_parent_name}-${project_name}"
}

red() { echo -ne "\e[91m"; echo -n "$@"; echo -e "\e[39m"; }
green() { echo -ne "\e[92m"; echo -n "$@"; echo -e "\e[39m"; }
yellow() { echo -ne "\e[93m"; echo -n "$@"; echo -e "\e[39m"; }
blue() { echo -ne "\e[94m"; echo -n "$@"; echo -e "\e[39m"; }
magenta() { echo -ne "\e[95m"; echo -n "$@"; echo -e "\e[39m"; }
__() { echo -n '    '; [ -n "$1" ] && echo "$@" || echo -n ; }
____() { echo; }

pregQuote() {
    local string="$1"
    # karakter dot (.), menjadi slash dot (\.)
    sed "s/\./\\\./g" <<< "$string"
}

blue '######################################################################'
blue '#                                                                    #'
blue '# GAK PAKE LAMA - DRUPAL VARIATION 1                                 #'
blue '#                                                                    #'
blue '######################################################################'
____

e Version 0.1.0
____

yellow -- START -------------------------------------------------------------
____

yellow User variable.
magenta 'project_name="'$project_name'"'
[ -n $project_parent_name ] && magenta 'project_parent_name="'$project_parent_name'"'
[ -n $domain_strict ] && magenta 'domain_strict="'$domain_strict'"'
[ ${#domain[@]} -gt 0 ] && {
    _value=
    for (( i=0; i < ${#domain[@]} ; i++ )); do
        _value+=" \"${domain[$i]}\""
    done
    magenta 'domain=('${_value:1}')'
} || {
    magenta 'domain=()'
}
magenta 'db_name="'$db_name'"'
magenta 'project_dir="'$project_dir'"'
magenta 'nginx_config_file="'$nginx_config_file'"'
magenta 'subdomain_localhost="'$subdomain_localhost'"'
magenta 'sites_subdir="'$sites_subdir'"'
____

yellow Define variable.
magenta 'DB_USER_HOST="'$DB_USER_HOST'"'
____

yellow Mengecek akses root.
if [[ "$EUID" -ne 0 ]]; then
	red This script needs to be run with superuser privileges.; exit
else
    __ Privileges.
fi
____

aptinstalled=$(apt --installed list 2>/dev/null)

downloadApplication() {
    yellow Melakukan instalasi aplikasi "$@".
    local aptnotfound=
    for i in "$@"; do
        if ! grep -q "^$i/" <<< "$aptinstalled";then
            aptnotfound+=" $i"
        fi
    done
    if [ -n "$aptnotfound" ];then
        __ Menginstal.
        magenta apt install -y"$aptnotfound"
        apt install -y $aptnotfound
        aptinstalled=$(apt --installed list 2>/dev/null)
    else
        __ Aplikasi sudah terinstall seluruhnya.
    fi
}

validateApplication() {
    local aptnotfound=
    for i in "$@"; do
        if ! grep -q "^$i/" <<< "$aptinstalled";then
            aptnotfound+=" $i"
        fi
    done
    if [ -n "$aptnotfound" ];then
        __; red Gagal menginstall aplikasi:"$aptnotfound"; exit
    fi
}

# Berbagai cara mendetek aplikasi installed:
# 1. dpkg -l <package>
# 2. apt --installed list 2>/dev/null | grep -q <package>
# Point nomor 1 tidak valid pada kasus sbb:
# ```
# apt install -y apt-transport-https
# apt remove --purge apt-transport-https
# dpkg -l apt-transport-https ; echo $?
# ```
# Output:
# root@ubuntu:~# dpkg -l apt-transport-https ; echo $?
# Desired=Unknown/Install/Remove/Purge/Hold
# | Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
# |/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
# ||/ Name                Version      Architecture Description
# +++-===================-============-============-=================================
# un  apt-transport-https <none>       <none>       (no description available)
# 0
#
application=
application+=' software-properties-common apt-transport-https'
application+=' zip unzip pwgen'
downloadApplication $application
validateApplication $application;
____

yellow Mengecek apakah nginx installed.
notfound=
if grep -q "^nginx/" <<< "$aptinstalled";then
    __ nginx installed.
else
    __ nginx not found.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Menginstall nginx
    magenta apt install nginx -y
    apt install nginx -y
    aptinstalled=$(apt --installed list 2>/dev/null)
    if grep -q "^nginx/" <<< "$aptinstalled";then
        __; green nginx installed.
    else
        __; red nginx not found.; exit
    fi
    ____
fi

yellow Mengecek apakah mariadb-server installed.
notfound=
if grep -q "^mariadb-server/" <<< "$aptinstalled";then
    __ mariadb-server installed.
else
    __ mariadb-server not found.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Menginstall mariadb-server
    magenta apt install mariadb-server -y
    apt install mariadb-server -y
    aptinstalled=$(apt --installed list 2>/dev/null)
    if grep -q "^mariadb-server/" <<< "$aptinstalled";then
        __; green mariadb-server installed.
    else
        __; red mariadb-server not found.; exit
    fi
    ____
fi

yellow Mengecek apakah mariadb-client installed.
notfound=
if grep -q "^mariadb-client/" <<< "$aptinstalled";then
    __ mariadb-client installed.
else
    __ mariadb-client not found.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Menginstall mariadb-client
    magenta apt install mariadb-client -y
    apt install mariadb-client -y
    aptinstalled=$(apt --installed list 2>/dev/null)
    if grep -q "^mariadb-client/" <<< "$aptinstalled";then
        __; green mariadb-client installed.
    else
        __; red mariadb-client not found.; exit
    fi
    ____
fi

yellow Mengecek konfigurasi MariaDB.
if [ -f /etc/mysql/mariadb.conf.d/50-server.cnf ];then
    if grep -q '^\s*bind-address\s*=\s*127.0.0.1\s*$' /etc/mysql/mariadb.conf.d/50-server.cnf;then
        __ Disable bind-address localhost '[1]'.
        sed -i 's/^bind-address/# bind-address/g' /etc/mysql/mariadb.conf.d/50-server.cnf
    elif grep -q '^\s*#\s*bind-address\s*=\s*127.0.0.1\s*$' /etc/mysql/mariadb.conf.d/50-server.cnf;then
        __ Disable bind-address localhost '[2]'.
    else
        __ Not found: bind-address localhost
    fi
else
    __; red File '`'/etc/mysql/mariadb.conf.d/50-server.cnf'`' tidak ditemukan.; exit
fi
____

yellow Mengecek direktori project '`'/var/www/project/$project_dir'`'.
notfound=
if [ -d /var/www/project/$project_dir ] ;then
    __ Direktori ditemukan.
else
    __ Direktori tidak ditemukan.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Membuat direktori project.
    magenta mkdir -p /var/www/project/$project_dir
    mkdir -p /var/www/project/$project_dir
    if [ -d /var/www/project/$project_dir ] ;then
        __; green Direktori berhasil dibuat.
    else
        __; red Direktori gagal dibuat.; exit
    fi
    ____
fi

# Credit:
# https://launchpad.net/~ondrej/+archive/ubuntu/php
addRepositoryPpaOndrejPhp() {
    local notfound=
    yellow Mengecek source PPA ondrej/php
    cd /etc/apt/sources.list.d
    if grep --no-filename -R -E "/ondrej/php/" | grep -q -v -E '^\s*#';then
        __ Sudah terdapat di direktori '`'/etc/apt/sources.list.d'`'.
    else
        notfound=1
        __ Tidak terdapat di direktori '`'/etc/apt/sources.list.d'`'.
    fi
    if [ -n "$notfound" ];then
        yellow Menambahkan source PPA ondrej/php
        magenta add-apt-repository ppa:ondrej/php -y
        magenta apt update -y
        add-apt-repository ppa:ondrej/php -y
        apt update -y
        # deb http://ppa.launchpad.net/ondrej/php/ubuntu focal main
        # deb https://ppa.launchpadcontent.net/ondrej/php/ubuntu/ jammy main
        if grep --no-filename -R -E "/ondrej/php/" | grep -q -v -E '^\s*#';then
            __; green Sudah terdapat di direktori '`'/etc/apt/sources.list.d'`'.
        else
            __; red Tidak terdapat di direktori '`'/etc/apt/sources.list.d'`'.;  exit
        fi
    fi
}

installphp() {
    local PHP_VERSION=$1
    local PRETTY_NAME NAME VERSION_ID VERSION VERSION_CODENAME
    local ID ID_LIKE HOME_URL SUPPORT_URL BUG_REPORT_URL PRIVACY_POLICY_URL
    local UBUNTU_CODENAME
    . /etc/os-release
    magenta 'ID="'$ID'"'
    magenta 'VERSION_ID="'$VERSION_ID'"'
    case $ID in
        ubuntu)
            case "$VERSION_ID" in
                22.04)
                    case "$PHP_VERSION" in
                        7.4)
                            addRepositoryPpaOndrejPhp
                            yellow Menginstall php7.4
                            magenta apt install php7.4 -y
                            apt install php7.4 -y
                            ;;
                        8.1)
                            yellow Menginstall php8.1
                            magenta apt install php -y
                            apt install php -y
                            # libapache2-mod-php8.1 php php8.1 php8.1-cli php8.1-common php8.1-opcache php8.1-readline
                    esac
                ;;
                *) red OS "$ID" version "$VERSION_ID" not supported; exit;
            esac
            ;;
        *) red OS "$ID" not supported; exit;
    esac
}

yellow Mengecek apakah PHP version 8.1 installed.
notfound=
string=php8.1
string_quoted=$(pregQuote "$string")
if grep -q "^${string_quoted}/" <<< "$aptinstalled";then
    __ PHP 8.1 installed.
else
    __ PHP 8.1 not found.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Menginstall PHP 8.1
    installphp 8.1
    aptinstalled=$(apt --installed list 2>/dev/null)
    if grep -q "^${string_quoted}/" <<< "$aptinstalled";then
        __; green PHP 8.1 installed.
    else
        __; red PHP 8.1 not found.; exit
    fi
    ____
fi

yellow Memastikan command exists
__ sudo mysql nginx php
command -v "sudo" >/dev/null || { red "sudo command not found."; exit 1; }
command -v "mysql" >/dev/null || { red "mysql command not found."; exit 1; }
command -v "nginx" >/dev/null || { red "nginx command not found."; exit 1; }
command -v "php" >/dev/null || { red "php command not found."; exit 1; }
____

yellow Mencari informasi nginx.
conf_path=$(nginx -V 2>&1 | grep -o -P -- '--conf-path=\K(\S+)')
magenta conf_path="$conf_path"
user_nginx=$(cat "$conf_path" | grep -o -P 'user\s+\K([^;]+)')
magenta user_nginx="$user_nginx"
____

yellow Mengecek database '`'$db_name'`'.
msg=$(mysql --silent --skip-column-names -e "select schema_name from information_schema.schemata where schema_name = '$db_name'")
notfound=
if [[ $msg == $db_name ]];then
    __ Database ditemukan.
else
    __ Database tidak ditemukan
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Membuat database.
    mysql -e "create database $db_name character set utf8 collate utf8_general_ci;"
    msg=$(mysql --silent --skip-column-names -e "select schema_name from information_schema.schemata where schema_name = '$db_name'")
    if [[ $msg == $db_name ]];then
        __; green Database ditemukan.
    else
        __; red Database tidak ditemukan; exit
    fi
    ____
fi

databaseCredential() {
    if [ -f /var/www/project/$project_dir/credential/database ];then
        local DB_USER DB_USER_PASSWORD
        . /var/www/project/$project_dir/credential/database
        db_user=$DB_USER
        db_user_password=$DB_USER_PASSWORD
    else
        db_user="$project_name"
        [ -n "$project_parent_name" ] && {
            db_user=$project_parent_name
        }
        db_user_password=$(pwgen -s 32 -1)
        mkdir -p /var/www/project/$project_dir/credential
        cat << EOF > /var/www/project/$project_dir/credential/database
DB_USER=$db_user
DB_USER_PASSWORD=$db_user_password
EOF
        chmod 0500 /var/www/project/$project_dir/credential
        chmod 0400 /var/www/project/$project_dir/credential/database
    fi
}

yellow Mengecek database credentials.
databaseCredential
if [[ -z "$db_user" || -z "$db_user_password" ]];then
    __; red Informasi credentials tidak lengkap: '`'/var/www/project/$project_dir/credential/database'`'.; exit
else
    magenta db_user="$db_user"
    magenta db_user_password="$db_user_password"
fi
____

yellow Mengecek user database '`'$db_user'`'.
msg=$(mysql --silent --skip-column-names -e "select COUNT(*) FROM mysql.user WHERE user = '$db_user';")
notfound=
if [ $msg -gt 0 ];then
    __ User database ditemukan.
else
    __ User database tidak ditemukan.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Membuat user database.
    mysql -e "create user '${db_user}'@'${DB_USER_HOST}' identified by '${db_user_password}';"
    msg=$(mysql --silent --skip-column-names -e "select COUNT(*) FROM mysql.user WHERE user = '$db_user';")
    if [ $msg -gt 0 ];then
        __; green User database ditemukan.
    else
        __; red User database tidak ditemukan; exit
    fi
    ____
fi

yellow Mengecek grants user '`'$db_user'`' ke database '`'$db_name'`'.
notfound=
msg=$(mysql "$db_name" --silent --skip-column-names -e "show grants for ${db_user}@${DB_USER_HOST}")
# GRANT USAGE ON *.* TO `xxx`@`localhost` IDENTIFIED BY PASSWORD '*650AEE8441BAF8090D260F1E4A0430DD2AF92FBA'
# GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, REFERENCES, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, EVENT, TRIGGER ON `xxx\\_%`.* TO `xxx`@`localhost`
# GRANT USAGE ON *.* TO `yyy`@`localhost` IDENTIFIED BY PASSWORD '*23FF9BDB84CBF879F19D46CB6B85F0550CB64F5C'
# GRANT ALL PRIVILEGES ON `yyy_drupal`.* TO `yyy`@`localhost`
# GRANT ALL PRIVILEGES ON `yyy_drupal\\_%`.* TO `yyy`@`localhost`
# "The first grant was auto-generated." Source: https://phoenixnap.com/kb/mysql-show-user-privileges
if grep -q "GRANT.*ON.*${db_name}.*TO.*${db_user}.*@.*${DB_USER_HOST}.*" <<< "$msg";then
    __ Granted.
else
    __ Not granted.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Memberi grants user '`'$db_user'`' ke database '`'$db_name'`'.
    mysql -e "grant all privileges on \`${db_name}\`.* TO '${db_user}'@'${DB_USER_HOST}';"
    mysql -e "grant all privileges on \`${db_name}\_%\`.* TO '${db_user}'@'${DB_USER_HOST}';"
    msg=$(mysql "$db_name" --silent --skip-column-names -e "show grants for ${db_user}@${DB_USER_HOST}")
    if grep -q "GRANT.*ON.*${db_name}.*TO.*${db_user}.*@.*${DB_USER_HOST}.*" <<< "$msg";then
        __; green Granted.
    else
        __; red Not granted.; exit
    fi
    ____
fi

# Source: https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
downloadComposer() {
    EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    magenta php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"
    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
    then
        >&2 echo 'ERROR: Invalid installer checksum'
        rm composer-setup.php
        exit 1
    fi
    magenta php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    RESULT=$?
    rm composer-setup.php
    return $RESULT
}

yellow Mengecek '`'composer'`' command.
notfound=
if `command -v "composer" >/dev/null`;then
    __ Command ditemukan.
else
    __ Command tidak ditemukan.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Mendownload dan menginstall composer.
    if downloadComposer;then
        __; green Install success.
    else
        __; red Install failed.; exit
    fi
    ____
fi

yellow Mengecek file '`'composer.json'`' untuk project '`'drupal/recommended-project'`'
notfound=
if [ -f /var/www/project/$project_dir/drupal/composer.json ];then
    __ File '`'composer.json'`' ditemukan.
else
    __ File '`'composer.json'`' tidak ditemukan.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Mendownload composer.json untuk project '`'drupal/recommended-project'`'.
    mkdir -p /var/www/project/$project_dir/drupal
    chown $user_nginx:$user_nginx /var/www/project/$project_dir/drupal
    cd /var/www/project/$project_dir/drupal
    # https://www.drupal.org/docs/develop/using-composer/manage-dependencies
    magenta composer create-project --no-install drupal/recommended-project .
    sudo -u $user_nginx HOME='/tmp' -s composer create-project --no-install drupal/recommended-project .
    ____
fi

yellow Mengecek dependencies menggunakan Composer.
notfound=
cd /var/www/project/$project_dir/drupal
msg=$(sudo -u $user_nginx HOME='/tmp' -s composer show 2>&1)
if ! grep -q '^No dependencies installed.' <<< "$msg";then
    __ Dependencies installed.
else
    __ Dependencies not installed.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Mendownload dependencies menggunakan Composer.
    downloadApplication php8.1-xml php8.1-gd
    validateApplication php8.1-xml php8.1-gd
    cd /var/www/project/$project_dir/drupal
    magenta composer -v install
    sudo -u $user_nginx HOME='/tmp' -s composer -v install
    ____
fi

yellow Mengecek drush.
notfound=
if sudo -u $user_nginx HOME='/tmp' -s composer show | grep -q '^drush/drush';then
    __ Drush exists.
else
    __ Drush is not exists.
    notfound=1
fi
____

if [ -n "$notfound" ];then
    yellow Memasang '`'Drush'`' menggunakan Composer.
    cd /var/www/project/$project_dir/drupal
    magenta composer -v require drush/drush
    sudo -u $user_nginx HOME='/tmp' -s composer -v require drush/drush
    if [ -f /var/www/project/$project_dir/drupal/vendor/bin/drush ];then
        __; green Binary Drush is exists.
    else
        __; red Binary Drush is not exists.; exit
    fi
    ____
fi

PATH=/var/www/project/$project_dir/drupal/vendor/bin:$PATH

yellow Mengecek domain-strict.
if [ -n "$domain_strict" ];then
    __ Instalasi Drupal tidak menggunakan '`'default'`'.
else
    __ Instalasi Drupal menggunakan '`'default'`'.
fi
____

yellow Mengecek apakah Drupal sudah terinstall sebagai singlesite '`'default'`'.
default_installed=
if drush status --field=db-status | grep -q '^Connected$';then
    __ Drupal site default installed.
    default_installed=1
else
    __ Drupal site default not installed.
fi
____

install_type=singlesite
yellow Mengecek Drupal multisite
if [ -n "$project_parent_name" ];then
    __ Project parent didefinisikan. Menggunakan Drupal multisite.
    if [ -f /var/www/project/$project_dir/drupal/web/sites/sites.php ];then
        __ Files '`'sites.php'`' ditemukan.
    else
        __ Files '`'sites.php'`' belum ditemukan.
    fi
    install_type=multisite
else
    __ Project parent tidak didefinisikan.
fi
if [[ -n "$domain_strict"  && -z "$default_installed" ]];then
    __ Domain strict didefinisikan. Menggunakan Drupal multisite.
    install_type=multisite
else
    __ Domain strict tidak didefinisikan.
fi
____

allsite=("${domain[@]}")
allsite+=("${subdomain_localhost}")
multisite_installed=
for eachsite in "${allsite[@]}" ;do
    yellow Mengecek apakah Drupal sudah terinstall sebagai multisite '`'$eachsite'`'.
    if [[ "sites/${sites_subdir}" == $(drush status --uri=$eachsite --field=site) ]];then
        __ Site direktori dari domain '`'$eachsite'`' sesuai, yakni: '`'sites/$sites_subdir'`'.
        if drush status --uri=$eachsite --field=db-status | grep -q '^Connected$';then
            __ Drupal site '`'$eachsite'`' installed.
            multisite_installed=1
        else
            __ Drupal site '`'$eachsite'`' not installed yet.
        fi
    else
        __ Site direktori dari domain '`'$eachsite'`' tidak sesuai.
    fi
    ____
done

if [[ -z "$domain_strict" && -z "$default_installed" && -n "$multisite_installed" ]];then
    yellow Drupal multisite sudah terinstall.
    __ Sebelumnya sudah di-install dengan option --domain-strict.
    __ Agar proses dapat dilanjutkan, perlu kerja manual dengan memperhatikan sbb:
    __ - Move file '`'settings.php'`' dari '`'sites/'<'sites_subdir'>''`' menjadi '`'sites/default'`'.
    __ - Move file-file script PHP yang di-include oleh '`'settings.php'`'.
    __ - Mengubah informasi public files pada config. Biasanya berada di '`'sites/'<'sites_subdir'>'/files'`'.
    __ - Menghapus informasi site di '`'sites/sites.php'`'.
    __; red Process terminated; exit
fi

if [[ -n "$domain_strict" && -n "$default_installed" ]];then
    yellow Drupal singlesite default sudah terinstall.
    __ Option --domain-strict tidak bisa digunakan.
    __ Agar proses dapat dilanjutkan, perlu kerja manual dengan memperhatikan sbb:
    __ - Move file '`'settings.php'`' dari '`'sites/default'`' menjadi '`'sites/'<'sites_subdir'>''`'.
    __ - Move file-file script PHP yang di-include oleh '`'settings.php'`'.
    __ - Mengubah informasi public files pada config. Biasanya berada di '`'sites/default/files'`'.
    __ - Menghapus informasi site di '`'sites/sites.php'`'.
    __; red Process terminated; exit
fi

drupalCredential() {
    local file=/var/www/project/$project_dir/credential/drupal/$subdomain_localhost
    if [ -f "$file" ];then
        local ACCOUNT_NAME ACCOUNT_PASS
        . "$file"
        account_name=$ACCOUNT_NAME
        account_pass=$ACCOUNT_PASS
    else
        account_name=system
        account_pass=$(pwgen -s 32 -1)
        mkdir -p /var/www/project/$project_dir/credential/drupal
        cat << EOF > "$file"
ACCOUNT_NAME=$account_name
ACCOUNT_PASS=$account_pass
EOF
        chmod 0500 /var/www/project/$project_dir/credential
        chmod 0500 /var/www/project/$project_dir/credential/drupal
        chmod 0400 /var/www/project/$project_dir/credential/drupal/$subdomain_localhost
    fi
}

yellow Mengecek drupal credentials.
drupalCredential
if [[ -z "$account_name" || -z "$account_pass" ]];then
    __; red Informasi credentials tidak lengkap: '`'/var/www/project/$project_dir/credential/drupal/$subdomain_localhost'`'.; exit
else
    magenta account_name="$account_name"
    magenta account_pass="$account_pass"
fi
____

if [[ $install_type == 'singlesite' && -z "$default_installed" ]];then
    yellow Install Drupal site default.
    magenta drush site:install --yes \
        --account-name="$account_name" --account-pass="$account_pass" \
        --db-url=mysql://${db_user}:${db_user_password}@${DB_USER_HOST}/${db_name}
    sudo -u $user_nginx HOME='/tmp' PATH=/var/www/project/$project_dir/drupal/vendor/bin:$PATH -s \
        drush site:install --yes \
            --account-name="$account_name" --account-pass="$account_pass" \
            --db-url=mysql://${db_user}:${db_user_password}@${DB_USER_HOST}/${db_name}
    if drush status --field=db-status | grep -q '^Connected$';then
        __; green Drupal site default installed.
    else
        __; red Drupal site default not installed.; exit
    fi
    ____
fi

if [[ $install_type == 'multisite' && -z "$multisite_installed" ]];then
    yellow Install Drupal multisite.
    magenta drush site:install --yes \
        --account-name="$account_name" --account-pass="$account_pass" \
        --db-url=mysql://${db_user}:${db_user_password}@${DB_USER_HOST}/${db_name} \
        --sites-subdir=${sites_subdir}
    sudo -u $user_nginx HOME='/tmp' PATH=/var/www/project/$project_dir/drupal/vendor/bin:$PATH -s \
        drush site:install --yes \
            --account-name="$account_name" --account-pass="$account_pass" \
            --db-url=mysql://${db_user}:${db_user_password}@${DB_USER_HOST}/${db_name} \
            --sites-subdir=${sites_subdir}
    if [ -f /var/www/project/$project_dir/drupal/web/sites/sites.php ];then
        __; green Files '`'sites.php'`' ditemukan.
    else
        __; red Files '`'sites.php'`' tidak ditemukan.; exit
    fi
    php=$(cat <<'EOF'
$args = $_SERVER['argv'];
array_shift($args);
$file = $args[0];
array_shift($args);
$sites_subdir = $args[0];
array_shift($args);
include($file);
if (!isset($sites)) {
    $sites = [];
}
while ($site = array_shift($args)) {
    $sites[$site] = $sites_subdir;
}
$content = '$sites = '.var_export($sites, true).';'.PHP_EOL;
$content = <<< EOF
<?php
$content
EOF;
file_put_contents($file, $content);
EOF
)
    sudo -u $user_nginx \
        php -r "$php" \
            /var/www/project/$project_dir/drupal/web/sites/sites.php \
            "$sites_subdir" \
            "${allsite[@]}"
    error=
    for eachsite in "${allsite[@]}" ;do
        if [[ "sites/${sites_subdir}" == $(drush status --uri=$eachsite --field=site) ]];then
            __; green Site direktori dari domain '`'$eachsite'`' sesuai, yakni: '`'sites/$sites_subdir'`'.
        else
            __; red Site direktori dari domain '`'$eachsite'`' tidak sesuai.
            error=1
        fi
        if drush status --uri=$eachsite --field=db-status | grep -q '^Connected$';then
            __; green Drupal site '`'$eachsite'`' installed.
        else
            __; red Drupal site '`'$eachsite'`' not installed yet.
            error=1
        fi
    done
    if [ -n "$error" ];then
        exit
    fi
    ____
fi

yellow Menyimpan credentials berdasarkan domain.
cd /var/www/project/$project_dir/credential/drupal/
magenta ls /var/www/project/$project_dir/credential/drupal/
for string in "${domain[@]}" ;do
    if [[ ! -L /var/www/project/$project_dir/credential/drupal/$string ]];then
        __; magenta ln -sf $subdomain_localhost $string
        ln -sf $subdomain_localhost $string
    fi
    __ $string '->' $(basename $(realpath $string))
done
____

downloadApplication php8.1-fpm
validateApplication php8.1-fpm
____

yellow Mengecek apakah nginx configuration
notfound=
file_config=$(grep -R -l -E "^\s*root\s+/var/www/project/${project_dir}/drupal/web\s*;" /etc/nginx/sites-enabled)
[ -n "$file_config" ] && {
    file_config=$(realpath $file_config)
    __ File config found: '`'$file_config'`'.;
} || {
    __ File config not found.;
    notfound=1
}
____

backupFile() {
    local oldpath="$1" i newpath
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
    mv "$oldpath" "$newpath"
    return $?
}

if [ -n "$notfound" ];then
    yellow Membuat nginx config.
    if [ -f /etc/nginx/sites-available/$nginx_config_file ];then
        __ Backup file /etc/nginx/sites-available/$nginx_config_file
        backupFile /etc/nginx/sites-available/$nginx_config_file
    fi
    cat <<'EOF' > /etc/nginx/sites-available/$nginx_config_file
server {
    listen 80;
    listen [::]:80;
    root /var/www/project/PROJECT_DIR/drupal/web;
    index index.php;
    server_name SUBDOMAIN_LOCALHOST;
    location / {
        try_files $uri /index.php$is_args$args;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
    }
}
EOF
    sed -i "s|PROJECT_DIR|${project_dir}|g" /etc/nginx/sites-available/$nginx_config_file
    sed -i "s|SUBDOMAIN_LOCALHOST|${subdomain_localhost}|g" /etc/nginx/sites-available/$nginx_config_file
    cd /etc/nginx/sites-enabled/
    ln -sf ../sites-available/$nginx_config_file
    nginx -s reload
    file_config=$(grep -R -l -E "^\s*root\s+/var/www/project/${project_dir}/drupal/web\s*;" /etc/nginx/sites-enabled)
    [ -n "$file_config" ] && {
        file_config=$(realpath $file_config)
        __; green File config found: '`'$file_config'`'.;
    } || {
        __; red File config not found.; exit
    }
    ____
fi

yellow Mengecek domain di nginx config.
reload=
allsite=("${domain[@]}")
allsite+=("${subdomain_localhost}")
for string in "${allsite[@]}" ;do
    notfound=
    string_quoted=$(pregQuote "$string")
    if grep -q -E "^\s*server_name\s+.*$string_quoted.*;\s*$" "$file_config";then
        __ Domain "$string" sudah terdapat pada file config.
    else
        __ Domain "$string" belum terdapat pada file config.
        notfound=1
    fi
    if [ -n "$notfound" ];then
        sed -i -E "s/server_name([^;]+);/server_name\1 "${string}";/" "$file_config"
        if grep -q -E "^\s*server_name\s+.*$string_quoted.*;\s*$" "$file_config";then
            __; green Domain "$string" sudah terdapat pada file config.
            reload=1
        else
            __; red Domain "$string" belum terdapat pada file config.; exit
        fi
    fi
done
if [ -n "$reload" ];then
    nginx -s reload
fi
____

yellow Dump Credentials.
magenta cat /var/www/project/$project_dir/credential/database
cat /var/www/project/$project_dir/credential/database
magenta cat /var/www/project/$project_dir/credential/drupal/$subdomain_localhost
cat /var/www/project/$project_dir/credential/drupal/$subdomain_localhost
for string in "${domain[@]}" ;do
    magenta cat /var/www/project/$project_dir/credential/drupal/$string
    cat /var/www/project/$project_dir/credential/drupal/$string
done
____

yellow -- FINISH ------------------------------------------------------------
____

exit 0

parse-options.sh \
--without-end-options-double-dash \
--compact \
--clean \
--no-hash-bang \
--no-original-arguments \
--no-error-invalid-options \
--no-error-require-arguments << EOF | clip
FLAG=(
--domain-strict
)
VALUE=(
--project-name
--project-parent-name
)
MULTIVALUE=(
--domain
)
EOF
