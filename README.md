# Simple Bash Script for Auto Installation Drupal

## Prerequisite

```
sudo apt update
sudo apt install wget -y
```

To avoid interruption because of kernel update, it is recommend to restart
machine after upgrade if you start from empty virtual machine instance.

```
apt upgrade
init 6
```

## Quick Mode Install

Login as root.

```
sudo su
```

Download.

```
mkdir -p ~/bin
cd ~/bin
wget -q https://github.com/ijortengab/drupal-autoinstaller/raw/master/drupal-autoinstaller.sh -O drupal-autoinstaller.sh
chmod a+x drupal-autoinstaller.sh
cd - >/dev/null
```

Make sure that directory `~/bin` has been include as `$PATH` in `~/.profile`.

```
command -v drupal-autoinstaller.sh >/dev/null || {
    PATH="$HOME/bin:$PATH"
    cat << 'EOF' >> ~/.profile
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi
EOF
}
```

then feels free to execute command. You will be prompt to some required value.

```
drupal-autoinstaller.sh --fast
```

## Advanced Install

Example 1. Change binary directory to `/usr/local/bin`.

Download.

```
cd /usr/local/bin
wget -q https://github.com/ijortengab/drupal-autoinstaller/raw/master/drupal-autoinstaller.sh -O drupal-autoinstaller.sh
chmod a+x drupal-autoinstaller.sh
cd -
```

If you change binary directory from default `$HOME/bin`, to others (i.e `/usr/local/bin`) then we must prepend environment variable (`$BINARY_DIRECTORY`) before execute the command.

Execute:

```
BINARY_DIRECTORY=/usr/local/bin drupal-autoinstaller.sh
```

Example 2. Change binary directory per project.

Attention. Variable project_name have to contain alphanumeric and underscores only.

```
unset project_name
until [[ -n "$project_name" ]];do read -p "Argument --project-name is required: " project_name; done
BINARY_DIRECTORY=/var/www/project/"$project_name"/bin drupal-autoinstaller.sh -- --project-name "$project_name"
```

Example 3. Pass some argument to command `gpl-drupal-setup-variation{n}.sh` using double dash as separator `--`.

```
drupal-autoinstaller.sh -- --timezone=Asia/Jakarta
```

Example 4. Fast version.

```
drupal-autoinstaller.sh --fast
```

## User Guide

Set the project name as identifier.

```
drupal-autoinstaller.sh -- --project-name mysite
```

Drupal will be installed quickly. Point browser to address http://mysite.drupal.localhost to see the results.

## Example

1. Simple Site

Install Drupal site with domain `systemix.id`.

We decide to set the project name similar to domain, namely `systemix`.

```
drupal-autoinstaller.sh -- --project-name systemix --domain systemix.id
```

Drupal will be installed quickly. Point browser to address http://systemix.drupal.localhost to see the results.

To review with the domain of `systemix.id`, then we use `curl`.

```
curl 127.0.0.1 -H "Host: systemix.id"
```

2. Multisite

Drupal has nice feature, that is multisite. We can create more than one site with the same of codebase.

Create main site first but it is not mandatory. We use domain `bta.my.id`.
We decide to set the project name similar to domain, namely `bta`.

```
drupal-autoinstaller.sh -- --project-name bta --domain bta.my.id
```

Create sub site. We use domain `finance.bta.my.id`.
We decide to set the project name similar to subdomain, namely `finance`.
We have to set the project parent name to `bta`, so we use the codebase of project `bta`.

```
drupal-autoinstaller.sh -- --project-parent-name bta --project-name finance --domain finance.bta.my.id
```

Drupal will installed quickly. Point browser to address `http://bta.drupal.localhost` for mainsite,
and `http://finance.bta.drupal.localhost` for subsite.

To review with the domain of `bta.my.id` and `finance.bta.my.id` then we use `curl`.

```
curl 127.0.0.1 -H "Host: bta.my.id"
curl 127.0.0.1 -H "Host: finance.bta.my.id"
```

We can manage multisite with `drush`, don't forget to use the `--uri` options.

```
project_dir=bta
PATH=/var/www/project/$project_dir/drupal/vendor/bin:$PATH
cd /var/www/project/$project_dir/drupal
drush status --uri=finance.bta.my.id
```
