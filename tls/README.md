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
  --kube-context "k3d-mongodb-mck-cluster" \
  --namespace "cert-manager" \
  --create-namespace \
  --set crds.enabled=true
```

You can confirm that cert-manager is installed in the `cert-manager` namespace.  
For checking, in K9s, press `:` type `namespace` and go to `cert-manager`.  
You should see these Pods:  

![Alt text](/img/cert-manager.png)

## Prepare certificate issuer and Certificate Authority (CA)

Create the certificate authority infrastructure that will issue the TLS certificates.  
All necessary YAMLs are prepared in the `/tls` folder.  
Make sure you run all commands from `./tls/` in your shell.  

### What we will do:
- Create a self-signed ClusterIssuer.
- Generate a CA certificate.
- Publish a cluster-wide CA issuer that all namespaces can use.
- Expose the CA bundle through a ConfigMap so MongoDB resources can use it.

### Create the CA

Let's create the necessary CA, Issuers and Secret:

```
kubectl apply -f certificate-authority.yaml
``` 

### Create the ConfigMap with the CA Certificate

This ConfigMap will be referenced in MCK CRs as the trusted CA bundle to:  
- Verify TLS server certificates for MongoDB, Ops Manager, Search, etc.
- Optionally validate client certs, LDAP server certs, etc

#### 1. Create a CA Certificate

Create a `ca.pem` file with the CA certificate.  
It takes the certificate from `root-secret` in `cert-manager` namespace.  

```
kubectl --context k3d-mongodb-mck-cluster \
  get secret root-secret \
  -n cert-manager \
  -o jsonpath="{.data['ca\\.crt']}" | base64 --decode > ca.pem
```

#### 2. Create the ConfigMap

The following command will:  
- create a `replica-set-ca-configmap` ConfigMap
- ConfigMap fields: `ca-pem`, `mms-ca.crt` and `ca.crt` 
- namespace: `mongodb-operator` 
- copy the CA certificate from the `ca.pem` file to the ConfigMap fields  

An example of the ConfigMap structure can be seen in `ConfigMap-example.yaml`.  

```
kubectl --context "k3d-mongodb-mck-cluster" \
  create configmap "replica-set-ca-configmap" \
  -n "mongodb-operator" \
  --from-file=ca-pem=./ca.pem \
  --from-file=mms-ca.crt=./ca.pem \
  --from-file=ca.crt=./ca.pem \
  --dry-run=client -o yaml | kubectl --context "k3d-mongodb-mck-cluster" apply -f -
```

Confirm that the `replica-set-ca-configmap` has been created.  
In K9s type `:` then `configmap`, and you should see it:  

![Alt text](/img/ca-configmap.png)


#### 2. Issue TLS certificates

Finally let's create the certificates.  
I recommend to review `certificates.yaml` to get familiar with it.  

Run:  

```
kubectl apply -f certificates.yaml
```

You should see the certificates `mdb-rs-server-tls`, `mdb-rs-search-tls`, and `om-http-cert`.  
In K9s type `:` and `certificates`:  

![Alt text](/img/certificates.png)


## Enable TLS in the current replica-set

Now that the certificates are issued, let's enable it in the current replica-set.  
We basically added `.spec.security.tls.enabled: true` and the respective CA. So run:  

```
kubectl apply -f replica-set-tls.yaml
```

Also let's enable TLS for Search:  

```
kubectl apply -f search-tls.yaml
```

Then TLS should be enabled and this should be shown in OpsManager UI for the `replica-set`:  

![Alt text](/img/om-tls-enabled.png)
