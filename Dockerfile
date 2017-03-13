FROM ubuntu:16.04
MAINTAINER Fabian Wenzelmann <fabianwen@posteo.eu>

# TODO maybe remove the mailadmin stuff, but I want to test...

RUN apt-get update \
  && echo postfix postfix/main_mailer_type string "'Internet Site'" | debconf-set-selections \
  &&  echo postfix postfix/mailname string temporary.example.com | debconf-set-selections \
  && apt-get install -y \
  rsyslog \
  supervisor \
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
  python3-requests \
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

# directory that stores the configuration (.cf files) of the user for dovecot
# from this directory we copy the configuration files to overwrite the
# dovecot default settings
VOLUME /doveconf

# create group for vmail, that is the group to own the dovecot mail directory
# also add the vmail user
RUN groupadd -g 5000 vmail && useradd -g vmail -u 5000 vmail -d /var/vmail -m && chown -R vmail.vmail /var/vmail

VOLUME /var/vmail

# fix spamassassin permission issue (as described in the ISP guide)
RUN adduser spamass-milter debian-spamd

# Copy entry script
COPY docker_entrypoint.sh /
RUN chmod +x /docker_entrypoint.sh
COPY mailadmin.sh /
RUN chmod +x /mailadmin.sh

# TODO: Remove this dirty fix if possible... strip and split don't work,
# matching an IP with sed oder grep is not so nice, so this python script
# See Dockerfile for details why I have to extract the ip from DB_HOST
COPY db_ip.py /

# some last volumes... the postfix spool (for example bounced mails)
# TODO Mr. J: Doesn't work
# VOLUME /var/spool/postfix
# log dir, in order to keep all log files
# TODO same here... no log files get created...
# maybe rsyslog can't write them becuase the directory has
# the wrong permissions?
# VOLUME /var/log

EXPOSE 25 587 143 993 110 995 4190

CMD /docker_entrypoint.sh
