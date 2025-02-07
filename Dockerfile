FROM alpine

LABEL maintainer Knut Ahlers <knut@ahlers.me>

ENV DI_VERSION 1.2.1

ENV USER0=test
ENV PASS0='$1$randomsa$hx1t1UTxVpQE8Kz9o6CRU/'
ENV UID0=1001

RUN apk --no-cache add bash curl openssh-server openssh-sftp-server openssl shadow \
 && mkdir /var/run/sshd && chmod 0755 /var/run/sshd \
 && curl -sSfLo /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v${DI_VERSION}/dumb-init_${DI_VERSION}_amd64 \
 && chmod +x /usr/local/bin/dumb-init \
 && apk --no-cache del curl

ADD start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

ADD create_user.sh /usr/local/bin/create_user.sh
RUN chmod +x /usr/local/bin/create_user.sh

ADD delete_user.sh /usr/local/bin/delete_user.sh
RUN chmod +x /usr/local/bin/delete_user.sh

ADD update_username.sh /usr/local/bin/update_username.sh
RUN chmod +x /usr/local/bin/update_username.sh

ADD update_user_password.sh /usr/local/bin/update_user_password.sh
RUN chmod +x /usr/local/bin/update_user_password.sh

ADD sshd_config /etc/ssh/sshd_config

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/start.sh"]
