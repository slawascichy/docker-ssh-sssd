#!/bin/bash
set -e

export SSSD_INIT_FILE=/var/log/sssd.init
export SSSD_CONFIG_FILE=/etc/sssd/sssd.conf

initSssd() {
    echo "Init sssd..."
    sed -i "s|_LDAP_URI_|${LDAP_URI}|g" $SSSD_CONFIG_FILE
    sed -i "s|_LDAP_USE_TSL_|${LDAP_USE_TSL}|g" $SSSD_CONFIG_FILE
    if [ "true" == ${LDAP_USE_TSL} ] ; then
    	echo "Enable TSL communication..."
    	sed -i "s|_LDAP_AUTH_DISABLE_|#ldap_auth_disable_tls_never_use_in_production = false|g" $SSSD_CONFIG_FILE
    	sed -i "s|_LDAP_TLS_REQCERT_|#ldap_tls_reqcert = allow|g" $SSSD_CONFIG_FILE
    else 
    	echo "Disable TSL communication..."
    	sed -i "s|_LDAP_AUTH_DISABLE_|ldap_auth_disable_tls_never_use_in_production = true|g" $SSSD_CONFIG_FILE
    	sed -i "s|_LDAP_TLS_REQCERT_|ldap_tls_reqcert = never|g" $SSSD_CONFIG_FILE
    fi
    sed -i "s|_LDAP_SEARCH_BASE_|${LDAP_SEARCH_BASE}|g" $SSSD_CONFIG_FILE
    sed -i "s|_LDAP_USER_SEARCH_BASE_|${LDAP_USER_SEARCH_BASE}|g" $SSSD_CONFIG_FILE
    sed -i "s|_LDAP_ACCESS_FILTER_|${LDAP_ACCESS_FILTER}|g" $SSSD_CONFIG_FILE
    sed -i "s|_LDAP_GROUP_SEARCH_BASE_|${LDAP_GROUP_SEARCH_BASE}|g" $SSSD_CONFIG_FILE
    sed -i "s|_LDAP_GROUP_MEMBER_|${LDAP_GROUP_MEMBER}|g" $SSSD_CONFIG_FILE
    sed -i "s|_LDAP_BIND_DN_|${LDAP_BIND_DN}|g" $SSSD_CONFIG_FILE
    sed -i "s|_LDAP_BIND_PASSWORD_|${LDAP_BIND_PASSWORD}|g" $SSSD_CONFIG_FILE
    echo "session     required      pam_mkhomedir.so skel=/etc/skel umask=022" > /etc/pam.d/password-auth
    echo "session     required      pam_mkhomedir.so skel=/etc/skel umask=022" > /etc/pam.d/system-auth
    touch $SSSD_INIT_FILE
}

startSssd() {
	sshd
	echo "Starting sssd..."
	/usr/sbin/sssd -i -d 4
}


if [ "$(ls -A $SSSD_INIT_FILE)" ]; then
	startSssd
else
    initSssd
    startSssd
fi