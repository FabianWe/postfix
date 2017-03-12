FROM ubuntu:16.04
MAINTAINER Fabian Wenzelmann <fabianwen@posteo.eu>

# TODO maybe remove the mailadmin stuff, but I want to test...

RUN apt-get update \
  && echo postfix postfix/main_mailer_type string "'Internet Site'" | debconf-set-selections \
  &&  echo postfix postfix/mailname string temporary.example.com | debconf-set-selections \
  && apt-get install -y \
  rsyslog \
  postfix \
  postfix-mysql \
  dovecot-mysql \
  dovecot-pop3d \
  dovecot-imapd \
  dovecot-lmtpd \
  dovecot-managesieved \
  spamassassin \
  spamass-milter \
  python3 \
  python3-pip \
  python3-mysqldb \
  git

# TODO only required for mailadmin
RUN git clone https://github.com/FabianWe/pymailadmin.git /mailadmin
RUN pip3 install --upgrade pip && pip3 install urwid

# copy the default configuration
COPY default_conf /default_conf

# directory that stores the configuration (.cf files) of the user
# from this directory we copy the configuration files to overwrite the
# postfix default config
VOLUME /postconf

# directory for storing the ssl certificate and key
VOLUME /certs

# TODO this is not nice, but I have no other idea right now...
# the volumes are always owned by root, but the vmail user must have write access
# to the directory. So actually we add vmail to the sudo group and in the entrypoint
# change the permissions of /var/vmail s.t. any user in the sudo group can write to it:
# THAT'S NOT REALLY GOOD
# TODO this should not affect any vmail users outside the image?

# directory that stores the configuration (.cf files) of the user for dovecot
# from this directory we copy the configuration files to overwrite the
# dovecot default settings
VOLUME /doveconf

# create group for vmail, that is the group to own the dovecot mail directory
# also add the vmail user
RUN groupadd -g 5000 vmail && useradd -g vmail -u 5000 vmail -d /var/vmail -m && usermod -aG sudo vmail

VOLUME /var/vmail

# fix spamassassin permission issue (as described in the ISP guide)
RUN adduser spamass-milter debian-spamd

# Copy entry script
COPY docker_entrypoint.sh /
RUN chmod +x /docker_entrypoint.sh


CMD /docker_entrypoint.sh
