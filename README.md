# Simple Bash Script for Auto Installation Drupal

## Prerequisite

Login as root.

```
sudo apt update
sudo apt install wget -y
```

To avoid interruption because of kernel update, it is recommend to restart
machine after upgrade if you start from empty virtual machine instance.

```
apt upgrade -y
init 6
```

## Quick Mode Install

Login as root.

```
sudo su
```

Download and put the script in directory of `$PATH`.

```
wget -q https://github.com/ijortengab/drupal-autoinstaller/raw/master/drupal-autoinstaller.sh -O drupal-autoinstaller.sh
chmod a+x drupal-autoinstaller.sh
mv drupal-autoinstaller.sh -t /usr/local/bin
```

## Alternate Mode Install

Create personal binary directory.

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

## How to Use

**Example 1.**

Feels free to execute command. You will be prompt to some required value.

```
drupal-autoinstaller.sh --fast
```

**Example 2.**

Set the project name as identifier.

```
drupal-autoinstaller.sh --fast -- --project-name mysite
```

Drupal will be installed quickly. Point browser to address http://mysite.drupal.localhost to see the results.

**Example 3.**

All dependency script will be download to same location of `drupal-autoinstaller.sh`.
If you wish to store dependency to other location, use the environment variable
`BINARY_DIRECTORY` before execute the command.

Example: Store all script to `$HOME/bin`, then execute.

```
BINARY_DIRECTORY=$HOME/bin drupal-autoinstaller.sh --fast
```

**Example 4.**

Avoid prompt with non interractive mode with passing all required
argument of command `rcm-drupal-setup-variation{n}.sh` using double dash as
separator `--`.

```
drupal-autoinstaller.sh --fast \
    --variation 1 \
    -- \
    --project-name=$project_name \
    --project-parent-name='' \
    --domain='' \
    --timezone=Asia/Jakarta
```

## Case Study

1. Simple Site

Install Drupal site with domain `systemix.id`.

We decide to set the project name similar to domain, namely `systemix`.

```
drupal-autoinstaller.sh --fast -- --project-name systemix --domain systemix.id
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
drupal-autoinstaller.sh --fast -- --project-name bta --domain bta.my.id
```

Create sub site. We use domain `finance.bta.my.id`.
We decide to set the project name similar to subdomain, namely `finance`.
We have to set the project parent name to `bta`, so we use the codebase of project `bta`.

```
drupal-autoinstaller.sh --fast -- --project-parent-name bta --project-name finance --domain finance.bta.my.id
```

Drupal will installed quickly. Point browser to address `http://bta.drupal.localhost` for mainsite,
and `http://finance.bta.drupal.localhost` for subsite.

To review with the domain of `bta.my.id` and `finance.bta.my.id` then we use `curl`.

```
curl 127.0.0.1 -H "Host: bta.my.id"
curl 127.0.0.1 -H "Host: finance.bta.my.id"
```

## Drush

We can manage all project and all multisite with `drush`, execute the launcher with command:

```
. cd-drupal
```

## Available Variation

| Variation |  OS           |  Drupal |  PHP |
|:---------:|---------------|--------:|-----:|
|     1     |  Debian 11    |      10 |  8.2 |
|     2     |  Debian 11    |       9 |  8.1 |
|     3     |  Ubuntu 22.04 |      10 |  8.2 |
|     4     |  Ubuntu 22.04 |       9 |  8.1 |
|     5     |  Debian 12    |      10 |  8.2 |
|     6     |  Debian 12    |       9 |  8.1 |
|     7     |  Debian 12    |      10 |  8.3 |
|     8     |  Debian 11    |      10 |  8.3 |
|     9     |  Ubuntu 22.04 |      10 |  8.3 |
