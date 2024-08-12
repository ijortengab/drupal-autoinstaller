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

## Install

### Alternative 1: with RCM

Download `rcm` from Github.

```
cd /tmp
wget git.io/rcm
chmod a+x rcm
```

You can put `rcm` file anywhere in $PATH:

```
mv rcm -t /usr/local/bin
```

then..

```
rcm install drupal-autoinstaller ijortengab/drupal-autoinstaller drupal-autoinstaller.sh
```

or if you want alternate binary directory:

```
BINARY_DIRECTORY=$HOME/bin \
    rcm install drupal-autoinstaller ijortengab/drupal-autoinstaller drupal-autoinstaller.sh
```

### Alternative 2: with Direct Download

Download and put the script in directory of `$PATH`.

```
wget -q https://github.com/ijortengab/drupal-autoinstaller/raw/master/drupal-autoinstaller.sh -O drupal-autoinstaller
chmod a+x drupal-autoinstaller
```

You can put `drupal-autoinstaller` file anywhere in $PATH:

```
mv drupal-autoinstaller -t /usr/local/bin
```

## How to Use

Feels free to execute command. You will be prompt to some required value.

```
drupal-autoinstaller --fast
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
