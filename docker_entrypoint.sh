#!/bin/bash

POSTFIXCONF="/postfix_conf"
USERCONF="/postconf"
DEFAULTCONF="/default_conf"

# get some environment variables and set defaults if they don't exist
: ${DB_USER:=root}
: ${DB_PASSWORD:=PASSWORD}
: ${DB_HOST:=mysql}
: ${DB_NAME:=mailserver}

###### POSTFIX ######

# create the directory containing the actual postfix conf located at /postfix_conf
# if it already exists ignore it already exists remove it
if [ -d "$POSTFIXCONF" ]; then
  rm -rf "$POSTFIXCONF"
fi

# copy the postfix configuration
cp -R /etc/postfix "$POSTFIXCONF"

# function to replace the placeholders in the config files, i.e. {}
function repl {
  sed -i "s/\${DB_USER}/$DB_USER/g" $1
  sed -i "s/\${DB_PASSWORD}/$DB_PASSWORD/g" $1
  sed -i "s/\${DB_HOST}/$DB_HOST/g" $1
  sed -i "s/\${DB_NAME}/$DB_NAME/g" $1
}

# ignores empty results
shopt -s nullglob

# overwrite the config by the default configuration
for i in $DEFAULTCONF/*.cf ; do
  cp "$i" "$POSTFIXCONF"
done

# finally overwrite all defaults with the user specific options
for i in ${USERCONF}/*.cf ; do
  cp "$i" "$POSTFIXCONF"
done

# replace the placeholders for each cf file
for i in $POSTFIXCONF/*.cf ; do
  repl $i
done

# configure the postfix main.cf file
# first figure out if the HOSTNAME variable is set, if yes use the hostname
if [ -z ${MAIL_HOSTNAME+x} ]; then
  echo "WARNING: MAIL_HOSTNAME is not set, not changing the configuration"
else
  sed -i "s/myhostname =.*/myhostname = $MAIL_HOSTNAME/g" "$POSTFIXCONF/main.cf"
  # edit /etc/mailname
  # TODO is this ok???
  echo $MAIL_HOSTNAME > /etc/mailname
fi


###### END POSTFIX ######



tail -f /etc/passwd
