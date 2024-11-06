FROM ubuntu

RUN apt-get update && apt-get install -y \
  sssd \
  krb5-user \
  openssh-server \
  openssh-client

# Potrzebujemy certyfikaty CA by mós skonfigurować SSL dla LDAP
RUN mkdir -p /opt/cacerts
COPY assets/cacerts/* /opt/cacerts

COPY assets/etc/krb5.conf /etc/krb5.conf
RUN chown root:root /etc/krb5.conf && chmod 644 /etc/krb5.conf
COPY assets/etc/nsswitch.conf /etc/nsswitch.conf
RUN chown root:root /etc/nsswitch.conf && chmod 644 /etc/nsswitch.conf

COPY assets/etc/sssd.conf /etc/sssd/sssd.conf
RUN chown root:root /etc/sssd/sssd.conf && chmod 600 /etc/sssd/sssd.conf
RUN mkdir -p /run/sshd && chown root:root /run/sshd && chmod 755 /run/sshd
RUN mkdir -p /opt/ibpmusers && chmod 777 /opt/ibpmusers

COPY assets/start-service.sh /start-service.sh
RUN chown root:root /start-service.sh && chmod 755 /start-service.sh

VOLUME /var/lib/sss
CMD ["/start-service.sh"]
