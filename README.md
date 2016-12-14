# letsencrypt-kubernetes

A docker image suitable for requesting new certificates from letsencrypt,
and storing them in a secret on kubernetes.

Available on docker hub as [ployst/letsencrypt](https://hub.docker.com/r/ployst/letsencrypt)

## Purpose

To provide an application that owns certificate requesting and storing.

 - To serve acme requests to letsencrypt (given that you direct them to this
   container)
 - To regularly (monthly) ask for new certificates.
 - To store those new certificates in a secret on kubernetes.

## Useful commands

### Generate a new set of certs

Once this container is running you can generate new certificates using:

```
kubectl exec -it <pod> -- bash -c 'EMAIL=fred@fred.com DOMAINS=example.com foo.example.com ./fetch_certs.sh'
```

### Save the set of certificates as a secret

```
kubectl exec -it <pod> -- bash -c 'DOMAINS=example.com foo.example.com ./save_certs.sh'
```

### Refresh the certificates

```
kubectl exec -it <pod> -- bash -c 'EMAIL=fred@fred.com DOMAINS=example.com foo.example.com SECRET_NAME=foo DEPLOYMENTS=bar ./refresh_certs.sh'
```

## Environment variables:

 - EMAIL - the email address to obtain certificates on behalf of.
 - DOMAINS - a space separated list of domains to obtain a certificate for.
 - LETSENCRYPT_ENDPOINT
   - If set, will be used to populate the /etc/letsencrypt/cli.ini file with
     the given server value. For testing use
     https://acme-staging.api.letsencrypt.org/directory
 - DEPLOYMENTS - a space separated list of deployments whose pods should be
   refreshed after a certificate save
 - SECRET_NAME - the name to save the secrets under
 - NAMESPACE - the namespace under which the secrets should be available
 - TYPE - the type of the secrets (default is Opaque)
 - CRON_FREQUENCY - the 5-part frequency of the cron job. Default is a random
   time in the range `0-59 0-23 1-27 * *`
