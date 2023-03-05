# Drupal Auto Installer

## Install

Download and move to PATH.

```
wget https://github.com/ijortengab/drupal-autoinstaller/raw/master/gpl-drupal-variation1.sh
chmod +x gpl-drupal-variation1.sh
mv gpl-drupal-variation1.sh -t /usr/local/bin
```

## Getting Started

Set the project name as identifier.

```
gpl-drupal-variation1.sh --project-name drupal
```

Drupal will be installed quickly. Point browser to address http://drupal.localhost to see the results.

## Example

1. Simple Site

Install Drupal site with domain `systemix.id`.
We decide to set the project name similar to domain, namely `systemix`.

```
gpl-drupal-variation1.sh --project-name systemix --domain systemix.id
```

Drupal will be installed quickly. Point browser to address http://systemix.localhost to see the results.

To review with the domain of `systemix.id`, then we use `curl`.

```
curl 127.0.0.1 -H "Host: systemix.id"
```

2. Multisite

Drupal has nice feature, that is multisite. We can create more than one site with the same of codebase.

Create main site first. We use domain `bta.my.id`.
We decide to set the project name similar to domain, namely `bta`.

```
gpl-drupal-variation1.sh --project-name bta --domain bta.my.id
```

Create sub site. We use domain `finance.bta.my.id`.
We decide to set the project name similar to subdomain, namely `finance`.
We have to set the project parent name to `bta`, so we use the codebase of project `bta`.

```
gpl-drupal-variation1.sh --project-parent-name bta --project-name finance --domain finance.bta.my.id
```

Drupal will installed quickly. Point browser to address `http://bta.localhost` for mainsite,
and `http://finance.bta.localhost` for subsite.

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

## Variation

### Variation 1

 - Install Drupal latest, PHP 8.2, nginx latest, mariadb latest, tested on Ubuntu 22.04.
 - Direcotry of project is inside `/var/www/project/`
