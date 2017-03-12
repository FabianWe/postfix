# postfix
A docker container for using postfix with dovecot and spamassassin.

**Still under development, do NOT use yet**.

This docker image installs postfix, dovecot and spamassassin and starts the with a default configuration that should be sound (no promises here).
Its configuration follows roughly the wonderful [ISPmail guide for Debian Jessie](https://workaround.org/ispmail/jessie) but with some notable changes.

Note that this image is not following the typical style that only one service should run in a container. I personally think that it's the best idea to bundle everything for the mailserver in one image. IMO postfix, dovecot and spamassassin belong together and should run together.

* We don't use debian jessie but Ubuntu (currently 16.04)
* For password encryption we use SHA-512 insteand of SHA-256
* No installation of a database on this system, link a mqsql container (such as mariadb)
* No installation of roundcube, there are also docker images for that

The aim is to provide you with an easy to install mail server that simply works but leaves you free to extend it until it fits your needs.

## Getting started
You should take a look at the example [docker-compose.yml](./docker-compose.yml) in this repository. It contains the most basic setup. The first thing you see in this file is the database (mariadb:). This is used as our mysql database to store all the stuff required for authentication. We create a volume for the data and also another volume *./docker-entrypoint-initdb.d:/docker-entrypoint-initdb.d*. So locally we need to create a directory *docker-entrypoint-initdb.d*. This directory contains a collection of sql scripts that will be executed when starting the database. In it you should add a file to initialize the mysql database. Luckily you don't have to write it yourself, it can be found in this repository: [mail.sql](./mail.sql). So just add the file to *docker-entrypoint-initdb.d* and it will create the database with all required tables for you.

## Configure Postfix / Dovecot
The image ships some reasonable (I hope so) configuration files, you can find them in the [default_conf/postfix](./default_conf/postfix) directory. In order to change some settings you can create a *postconf* directectory (and a directory *doveconf*). So create your own configuration files here. Take a look at the structure in the default config. To change the configuration copy a default file and change some lines. For postfix there is also an easier version using postconf (see below).

The configuration works as follows:

 1. Take all the default configuration files from /etc/postfix
 2. Overwrite those settings with the config files in [default_conf/postfix](./default_conf/postfix) and [default_conf/dovecot](./default_conf/dovecot). The files are arranged in the same way as in postfix / dovecot.
 3. Overwrite those settings with the files specified in */postconf*  and *doveconf* (the directories you mounted in the container)
 4. For postfix you can create a file called *postconf* inside the *postconf* directory. This file must include instructions that can be passed to the `postconf` command. This can be used for minor configurations (if you plan bigger changes you should consider to create your own config). Here is a small example of such a file:

```
message_size_limit=10000000
maximal_queue_lifetime=2d
bounce_queue_lifetime=5h
```
You probably want to adjust those to your needs: the message limit defaults to 5000000 bytes ~ 5MB, the lifetimes to just 2h (the postfix default for them is 5 days).

### Configure the Database
The image is based on a mysql database you link to your container. You don't have to copy your mysql information in every config file, the entrypoint script will replace all occurrences of the following variables from your config files with some environment variable:

 - ${DB_USER} gets replaced by the specified database user, defaults to *root*. Set environment variable DB_USER
 - ${DB_PASSWORD} gets replaced by your password, it defaults to *PASSWORD* but of course that is not very useful. Set environment variable DB_PASSWORD
 - ${DB_HOST} gets replaced by the host, this should be the link name of the mysql image, defaults to *mysql*. Set environment variable DB_HOST
 - ${DB_NAME} gets replaced by the name of the database, defaults to *mailserver*. Set environment variable DB_Name

Note that we actually don't replace the DB_HOST with the content of this variable but the IP of the linked database. Otherwise postfix and dovecot have problems accessing the database.

If you use my mysql proposal you only have to set the environment variable DB_PASSWORD, everything als is not required.
