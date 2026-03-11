# Enable TLS and create all the certificates

## What we will do:
- Create the certificates
- Enable TLS

## Prerequisites
If you've followed [these steps](https://github.com/vinilage/mck-om/tree/main) you are good to go!
- [A local Kubernetes cluster](https://github.com/vinilage/mck-om/tree/main) 
- [OpsManager deployed](https://github.com/vinilage/mck-om/tree/main)
- [A replica-set deployed](https://github.com/vinilage/mck-om/blob/main/replica-set/README.md) 
- [SCRUM authentication enabled and database users created](https://github.com/vinilage/mck-om/blob/main/user/README.md)

## Install cert-manager

To install `cert-manager` in the `cert-manager` namespace, run the following (it can take some time):

```
helm upgrade --install \
  cert-manager \
  oci://quay.io/jetstack/charts/cert-manager \
  --kube-context "k3d-my-k3d-cluster" \
  --namespace "cert-manager" \
  --create-namespace \
  --set crds.enabled=true
```

## Prepare certificate issuer and CA infrastructure

Create the certificate authority infrastructure that will issue TLS certificates.  
Go to `./tls/` folder in your shell.

### What we will do:
- Create a self-signed ClusterIssuer.
- Generate a CA certificate.
- Publish a cluster-wide CA issuer that all namespaces can use.
- Expose the CA bundle through a ConfigMap so MongoDB resources can use it.

Deploy a self-signed ClusterIssuer to mint the CA secret consumed by application workloads.

```
kubectl apply -f issuer.yaml
``` 

Deploy a certificate.

```
kubectl apply -f certificate-authority.yaml
``` 

Deploy a cluster-level issuer:

```
kubectl apply -f cluster-issuer.yaml
``` 

Create a config-map with the certificates:

```
kubectl --context "k3d-my-k3d-cluster" create configmap "replica-set-ca-configmap" -n "mongodb-operator" \
  --from-file=ca-pem="./" --from-file=mms-ca.crt="./" \
  --from-file=ca.crt="./" \
  --dry-run=client -o yaml | kubectl --context "k3d-my-k3d-cluster" apply -f -
```

Issue TLS certificates:

```
kubectl apply -f certificates.yaml
```
