# Drupal Auto Installer

The extension of `rcm`.

## Prerequisite

Login as root.

```
su -
```

If you start from empty virtual machine instance, it is recommend to upgrade
then restart machine to avoid interruption because of kernel update.

```
apt update -y
apt upgrade -y
init 6
```

Make sure `wget` command is exist.

```
apt install -y wget
```

## Install

### rcm

Download `rcm` from Github.

```
wget git.io/rcm
chmod a+x rcm
```

You can put `rcm` file anywhere in `$PATH`:

```
mv rcm -t /usr/local/bin
```

Always fast.

```
alias rcm='rcm --fast'
```

### rcm-drupal

Install `drupal` extension.

```
rcm install drupal
```

Enter value for `--url` option:

```
https://github.com/ijortengab/drupal-autoinstaller
```

Skip value for `--path` option. We use the default value.

## How to Use

Feels free to execute `drupal` command. You will be prompt to some required value.

```
rcm drupal
```

## Tips 1

Update if necessary.

```
rcm update drupal
```

## Tips 2

Install the additional extension.

```
rcm install drupal-adjust-file-system-outside-web-root --source drupal
```

Just execute.

```
rcm drupal-adjust-file-system-outside-web-root
```

Update if necessary.

```
rcm update drupal-adjust-file-system-outside-web-root
```

## Tips 3

There are two additional commands for you.

```
ls-drupal
```

```
. cd-drupal
```

Select the projects, then run drush.

```
drush status
```
