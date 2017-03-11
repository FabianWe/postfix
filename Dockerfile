FROM ubuntu:16.04
MAINTAINER Fabian Wenzelmann <fabianwen@posteo.eu>

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
  spamass-milter

# create a directory that stores the configuration (.cf files) of the user
# from this directory we copy the configuration files to overwrite the
# postfix default config
VOLUME /postconf
COPY default_conf /default_conf

# Copy entry script
COPY docker_entrypoint.sh /
RUN chmod +x /docker_entrypoint.sh

CMD /docker_entrypoint.sh
