# Simple Bash Script for Auto Installation Drupal

## Prerequisite

```
sudo apt update
sudo apt install wget -y
```

## Quick Mode Install

You will be prompt to some required value.

```
cd /tmp && wget -q https://github.com/ijortengab/drupal-autoinstaller/raw/master/drupal-autoinstaller.sh -O drupal-autoinstaller.sh && sudo -E bash drupal-autoinstaller.sh
```

## Advanced Install

Alternative 1. Change binary directory to all user inside `/usr/local/bin`.

```
cd /tmp
wget -q https://github.com/ijortengab/drupal-autoinstaller/raw/master/drupal-autoinstaller.sh -O drupal-autoinstaller.sh
sudo BINARY_DIRECTORY=/usr/local/bin -E bash drupal-autoinstaller.sh
```

Alternative 1.1. Change binary directory per project.

Attention. Variable project_name can only contain alphanumeric and underscores.

```
cd /tmp
unset project_name
until [[ -n "$project_name" ]];do read -p "Argument --project-name is required: " project_name; done
wget -q https://github.com/ijortengab/drupal-autoinstaller/raw/master/drupal-autoinstaller.sh -O drupal-autoinstaller.sh
sudo BINARY_DIRECTORY=/var/www/project/"$project_name"/bin -E bash drupal-autoinstaller.sh -- --project-name "$project_name"
```

Alternative 2. Pass some argument to setup.

```
cd /tmp
wget -q https://github.com/ijortengab/drupal-autoinstaller/raw/master/drupal-autoinstaller.sh -O drupal-autoinstaller.sh
sudo -E bash drupal-autoinstaller.sh -- --timezone=Asia/Jakarta
```

Alternative 3. Fast version.

```
cd /tmp
wget -q https://github.com/ijortengab/drupal-autoinstaller/raw/master/drupal-autoinstaller.sh -O drupal-autoinstaller.sh
sudo -E bash drupal-autoinstaller.sh --fast
```

## User Guide

Set the project name as identifier.

```
sudo -E bash drupal-autoinstaller.sh -- --project-name mysite
```

Drupal will be installed quickly. Point browser to address http://mysite.drupal.localhost to see the results.

## Example

1. Simple Site

Install Drupal site with domain `systemix.id`.

We decide to set the project name similar to domain, namely `systemix`.

```
sudo -E bash drupal-autoinstaller.sh -- --project-name systemix --domain systemix.id
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
sudo -E bash drupal-autoinstaller.sh -- --project-name bta --domain bta.my.id
```

Create sub site. We use domain `finance.bta.my.id`.
We decide to set the project name similar to subdomain, namely `finance`.
We have to set the project parent name to `bta`, so we use the codebase of project `bta`.

```
sudo -E bash drupal-autoinstaller.sh -- --project-parent-name bta --project-name finance --domain finance.bta.my.id
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
