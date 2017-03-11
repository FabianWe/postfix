# postfix
A docker container for using postfix with dovecot and spamassassin.

**Still under development, do NOT use yet**.

This docker image installs postfix, dovecot and spamassassin and starts the with a default configuration that should be sound (no promises here).
Its configuration follows roughly the wonderful [ISPmail guide for Debian Jessie](https://workaround.org/ispmail/jessie) but with some notable changes.

* We don't use debian jessie but Ubuntu (currently 16.04)
* For password encryption we use SHA-512 insteand of SHA-256
* No installation of a database on this system, link a mqsql container (such as mariadb)
* No installation of roundcube, there are also docker images for that

The aim is to provide you with an easy to install mail server that simply works but leaves you free to extend it until it fits your needs.

## Configure Postfix
The image ships some reasonable (I hope so) configuration files, you can find them in the [default_conf](./default_conf) directory. In order to change some settings you can create a *postconf* directory and mount it in the container at */postconf*. So create your own configuration files here. So to change the default configuration copy a default file and change some lines. All those files weill be included in the postfix configuration dir (the one that is usually found at /etc/postfix).

The configuration works as follows:

 1. Take all the default configuration files from /etc/postfix
 2. Overwrite those settings with the config files in [default_conf](./default_conf) (all files ending in *.cf)
 3. Overwrite those settings with the files specified in */postconf* (the directory you mounted in the container)

### Taking into account database information
The image is based on a mysql database you link to your container. You don't have to copy your mysql information in every config file, the entrypoint script will replace all occurrences of the following variables from your config file with some environment variable:

 - ${DB_USER} gets replaced by the specified database user, if the environment variable DB_USER  is not set root is assumed
 - ${DB_PASSWORD} gets replaced by your password, it defaults to PASSWORD but of course that is not very useful.
 - The database host is always mysql, the database name is always mailserver, so they don't get replaced and you can use them directly.
