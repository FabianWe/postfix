#!/bin/bash

POSTFIXCONF="/postfix_conf"
USERCONF="/postconf"
DEFAULTCONF="/default_conf"

# create the directory containing the actual postfix conf located at /postfix_conf
# if it already exists ignore it already exists do nothing
if [ ! -d "$POSTFIXCONF" ]; then
    cp -R /etc/postfix "$POSTFIXCONF"
fi

# overwrite the config by the default configuration
for i in $DEFAULTCONF/*.cf ; do
  cp "$i" "$POSTFIXCONF"
done

# finally overwrite all defaults with the user specific options
shopt -s nullglob
for i in ${USERCONF}/*.cf ; do
  echo "BLA $i"
done

tail -f /etc/passwd
