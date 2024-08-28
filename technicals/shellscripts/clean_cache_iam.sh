#!/usr/bin/env bash
#NAMESPACE=eric-eea-ns
TRUSTPASS=kvdbpass
# obtain a shell from IAM pod and change to the bin folder
cd /opt/jboss/keycloak/bin || exit
# setup variables in IAM pod
export ADMIN_PORT=8443
export USERNAME=admin
export USER_PWD=KeyCl0@kP@ssw0rd
export IAM_URL="https://eric-sec-access-mgmt-http:$ADMIN_PORT"
export KCADM_CONFIG_PATH="/opt/jboss/rundir-safe"
export KCADM_CONFIG_OPT="$KCADM_CONFIG_PATH/kcadm.config"
export REALM_NAME="local-ldap3"
# create a truststore and add SIP-TLS root CA certificate to it
keytool --import -alias sip-tls -storetype JKS -keystore $KCADM_CONFIG_PATH/kcadm.truststore \
  -storepass $TRUSTPASS -noprompt \
  -file /run/secrets/tls-int-ca-cert/cacertbundle.pem
# configure kcadm
./kcadm.sh config truststore --trustpass $TRUSTPASS $KCADM_CONFIG_PATH/kcadm.truststore --config "$KCADM_CONFIG_OPT"
# make sure to use HTTPS in the URL
export IAM_URL="https://eric-sec-access-mgmt-http:$ADMIN_PORT"
# Configure the admin CLI with administrator credentials
yes "$USER_PWD" | ./kcadm.sh config credentials \
  --server $IAM_URL/auth \
  --realm master --user $USERNAME --config "$KCADM_CONFIG_OPT"
# Set up the admin CLI according to the Configuring admin CLI section. Thereafter run the following commands (REALM_NAME should be the name of target realm where to clear cache).
cd /opt/jboss/keycloak/bin || exit
./kcadm.sh create clear-realm-cache -r $REALM_NAME -s realm=$REALM_NAME --config  "$KCADM_CONFIG_OPT"
./kcadm.sh create clear-user-cache -r $REALM_NAME -s realm=$REALM_NAME --config "$KCADM_CONFIG_OPT"
./kcadm.sh create clear-keys-cache -r $REALM_NAME -s realm=$REALM_NAME --config "$KCADM_CONFIG_OPT"
