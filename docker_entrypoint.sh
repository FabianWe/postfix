#!/bin/bash

# ignores empty results
shopt -s nullglob

POSTFIXCONF="/etc/postfix"
POSTFIXUSERCONF="/postconf"
POSTFIXDEFAULTCONF="/default_conf/postfix"

DOVECOTCONF="/etc/dovecot"
DOVECOTUSERCONF="/doveconf"
DOVECOTDEFAULTCONF="/default_conf/dovecot"

# get some environment variables and set defaults if they don't exist
: ${DB_USER:=root}
: ${DB_PASSWORD:=PASSWORD}
: ${DB_HOST:=mysql}
: ${DB_NAME:=mailserver}
: ${MESSAGE_SIZE_LIMIT:=6000000}

# function to replace the placeholders in the config files, i.e. ${...}
function repl {
  sed -i "s/\${DB_USER}/$DB_USER/g" $1
  sed -i "s/\${DB_PASSWORD}/$DB_PASSWORD/g" $1
  sed -i "s/\${DB_HOST}/$DB_HOST/g" $1
  sed -i "s/\${DB_NAME}/$DB_NAME/g" $1
  sed -i "s/\${MESSAGE_SIZE_LIMIT}/$MESSAGE_SIZE_LIMIT/g" $1
  if [ ! -z ${MAIL_HOSTNAME+x} ]; then
    sed -i "s/\${MAIL_HOSTNAME}/$MAIL_HOSTNAME/g" $1
  fi
}

###### POSTFIX ######

# overwrite the config by the default configuration
for i in $POSTFIXDEFAULTCONF/*.cf ; do
  cp "$i" "$POSTFIXCONF"
done

# finally overwrite all defaults with the user specific options
for i in ${POSTFIXUSERCONF}/*.cf ; do
  cp "$i" "$POSTFIXCONF"
done

# replace the placeholders for each cf file
for i in $POSTFIXCONF/*.cf ; do
  repl $i
done

# configure the postfix main.cf file
# first figure out if the HOSTNAME variable is set, if yes use the hostname
if [ -z ${MAIL_HOSTNAME+x} ]; then
  printf "WARNING: MAIL_HOSTNAME is not set, not changing the configuration. Things will not work...\n"
else
  sed -i "s/myhostname =.*/myhostname = $MAIL_HOSTNAME/g" "$POSTFIXCONF/main.cf"
  # edit /etc/mailname
  # TODO is this ok???
  echo $MAIL_HOSTNAME > /etc/mailname
fi

###### END POSTFIX ######

###### DOVECOT ######
# TODO as mentioned in Dockerfile, we have to change the permissions, which is
# not so nice after all
# TODO is it sufficient to do this in the Dockerfile?... anyway
chmod -R g+w /var/vmail

# overwrite the config by the default configuration
for i in $DOVECOTDEFAULTCONF/*.{conf,ext} ; do
  cp "$i" "$DOVECOTCONF"
done

# ... also for the subdir conf.d I'm to lazy to merge these things into one loop
for i in $DOVECOTDEFAULTCONF/conf.d/*.{conf,ext} ; do
  cp "$i" "$DOVECOTCONF/conf.d"
done

# finally overwrite all defaults with the user specific options
for i in ${DOVECOTUSERCONF}/*.{conf,ext} ; do
  cp "$i" "$DOVECOTCONF"
done

# again for the subdir
for i in ${DOVECOTUSERCONF}/conf.d/*.{conf,ext} ; do
  cp "$i" "$DOVECOTCONF/conf.d"
done

# replace the placeholders for each cf file
for i in $DOVECOTCONF/*.{conf,ext} ; do
  repl $i
done

# ... subdir
for i in $DOVECOTCONF/conf.d/*.{conf,ext} ; do
  repl $i
done

# change permission of database files
chown root:root "$DOVECOTCONF/dovecot-sql.conf.ext"
chmod go= "$DOVECOTCONF/dovecot-sql.conf.ext"

###### END DOVECOT ######

###### SPAMASSASSIN ######

# copy the config
cp /default_conf/spamassassin /etc/default/

# copy the spam-to-folder.sieve and compile it
if [ ! -d "$DOVECOTCONF/sieve-after" ]; then
  mkdir "$DOVECOTCONF/sieve-after"
fi
cp /default_conf/spam-to-folder.sieve "$DOVECOTCONF/sieve-after"
sievec "$DOVECOTCONF/sieve-after/spam-to-folder.sieve"

###### END SPAMASSASSIN ######

# start all services
# just to be sure run newaliases
newaliases
service rsyslog start
service dovecot start
service spamassassin start
service spamass-milter start
postfix start

# TODO only required for mailadmin
printf "[mysql]\nhost = $DB_HOST\ndb = $DB_NAME\nuser = $DB_USER\npassword = $DB_PASSWORD\n" > /mailadmin/.config

# TODO this is somehow a dirty hack, but postfix can't access the host mysql inside the container,
# it is very much isolated from the rest...
# see https://github.com/hardware/mailserver/issues/27
# so we search hosts for the line containing mysql and add the line to /var/spool/postfix/etc/hosts

tail -f /etc/passwd
