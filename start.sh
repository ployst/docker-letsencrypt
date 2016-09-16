#!/bin/bash

# Add a cron line with details of the current user etc
minute=$(echo $RANDOM % 60 | bc)
hour=$(echo $RANDOM % 23 | bc)
day=$(echo $RANDOM % 27 + 1 | bc)

CRON_FREQUENCY=${CRON_FREQUENCY:-"$minute $hour $day * *"}
NAMESPACE=${NAMESPACE:-default}

echo "Configuring cron..."
echo "DOMAINS: " $DOMAINS
echo "EMAIL: " $EMAIL
echo "DEPLOYMENTS: " $DEPLOYMENTS
echo "NAMESPACE: " $NAMESPACE
echo "SECRET_NAME: " $SECRET_NAME
echo "CRON frequency: " $CRON_FREQUENCY
# Once a month, fetch and save certs + restart pods.

# The process running under cron needs to know where the to find the kubernetes api
env_vars="PATH=$PATH KUBERNETES_PORT=$KUBERNETES_PORT KUBERNETES_PORT_443_TCP_PORT=$KUBERNETES_PORT_443_TCP_PORT KUBERNETES_SERVICE_PORT=$KUBERNETES_SERVICE_PORT KUBERNETES_SERVICE_HOST=$KUBERNETES_SERVICE_HOST KUBERNETES_PORT_443_TCP_PROTO=$KUBERNETES_PORT_443_TCP_PROTO KUBERNETES_PORT_443_TCP_ADDR=$KUBERNETES_PORT_443_TCP_ADDR KUBERNETES_PORT_443_TCP=$KUBERNETES_PORT_443_TCP"

line="$CRON_FREQUENCY $env_vars SECRET_NAME=$SECRET_NAME NAMESPACE=$NAMESPACE DEPLOYMENTS='$DEPLOYMENTS' DOMAINS='$DOMAINS' EMAIL=$EMAIL /bin/bash /letsencrypt/refresh_certs.sh >> /var/log/cron-encrypt.log 2>&1"
(crontab -u root -l; echo "$line" ) | crontab -u root -

if [ -n "${LETSENCRYPT_ENDPOINT+1}" ]; then
    echo "server = $LETSENCRYPT_ENDPOINT" >> /etc/letsencrypt/cli.ini
fi

# The process that identify and setup the admin-key to KUBECTL
# Note: This PATHS's has to be absolutes.
if [ -n "${KUBECTL_ACCESS_SECURED+1}" ] && [ "${KUBECTL_ACCESS_SECURED,,}" = "true" ]; then
  echo "Configuring KUBECTL keys..."
  echo "MASTER_HOST : ${MASTER_HOST}"
  echo "CA_CERT_PATH : ${CA_CERT_PATH}"
  echo "ADMIN_KEY_PATH : ${ADMIN_KEY_PATH}"
  echo "ADMIN_CERT_PATH : ${ADMIN_CERT_PATH}"

  kubectl config set-cluster default-cluster --server=https://${MASTER_HOST} --certificate-authority=${CA_CERT}
  kubectl config set-credentials default-admin --certificate-authority=${CA_CERT} --client-key=${ADMIN_KEY} --client-certificate=${ADMIN_CERT}
  kubectl config set-context default-system --cluster=default-cluster --user=default-admin
  kubectl config use-context default-system

 echo "KUBECTL: OK!"
fi

# Start cron
echo "Starting cron..."
cron &

echo "Starting nginx..."
nginx -g 'daemon off;'
