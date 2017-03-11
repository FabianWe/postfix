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
