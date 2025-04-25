# Deploy OpsManager and MongoDb on GKE 

## Overview

This repository shows how to deploy MongoDb Ops Manager and a replica set cluster on a GKE cluster using the MongoDB Enterprise Kubernetes Operator.

![Alt text](/images/mongodb-operator-img.png)

## Prerequisities

## Setup Infrastructure

To spin up the GKE cluster, run the makefile on the `setup` folder using this command 

```
make create-cluster \
  PROJECT_ID=project-name \
  CLUSTER_NAME=cluster-name \
  ZONE=zone \
  REGION=region \
```

Do not forget to add your configuration variables. 
This script provisions a 4-nodes GKE cluster and configure directly the kubeconfig entry to directly be able to connect into it.

Try the connection by running ``kubectl get nodes`` command. 

## Install the operator

To install the MongoDB Enterprise Kubernetes Operatorm run the makefile on the ``operator`` folder using the command ``make all``.

To verify the installation, run these command

```
helm list --namespace mongodb-operator
```
and

```
kubectl get pods -n mongodb-operator
```

## Deploy Ops Manager

Fill your credentials in the ``ops-manager/secret.yaml`` file.
Put the desired version of Ops Manager and the Application database ont the ``ops-manager/deploy.yaml`` 

After all, to deploy Ops Manager, run the following command 

```
make deploy
```

To generate the Ops Manager URL, run the following command
```
URL=http://$(kubectl -n mongodb-operator get svc ops-manager-svc-ext -o jsonpath='{.status.loadBalancer.ingress[0].ip}:{.spec.ports[0].port}')
echo $URL
```

## Deploy a replica set

First step is to generate the API Key through Ops Manager. To do so, go to ops-manager-db Organization > Access Managaer > Create API Key (as an Org Owner). Do not forget to add your IP address to the API access list. 

Complete the ``rep-set/secret.yaml`` then the ``rep-set/config-map.yaml`` to prepare the deployment of the replica set. 
Note: if you can't get the information, you can have the YAML files using the Kubernetes Setup on the organization settings.

![Alt text](/images/kubernetes-setup.png)

Run the following command in the ``rep-set`` folder to start deploying the replica-set under a new project.
```
make deploy
```

To troubleshoot evuentual IP issues, run the following command
```
kubectl describe mdb replica-set -n mongodb-operator 
```

### Connect to the replica set (from the pod)

To connect to the replica set from inside the cluster, run the following command
```
kubectl run -i --tty mongo-client --rm \
  --image=mongo \
  --restart=Never \
  -- bash
```

Inside the pod, you will run this following command
```
mongosh --host replica-set-0.replica-set-svc.mongodb-operator.svc.cluster.local --port 27017
```

Note: you can also find a way to connect by using this [link](https://www.mongodb.com/docs/ops-manager/v8.0/tutorial/connect-to-mongodb/)

### Connect to the replica set (using port-forward)

To forward a port from the MongoDB replica set to you local machine, run the following command
```
kubectl port-forward pod/replica-set-0 27017:27017 -n mongodb-operator

```

Once it is set,up, connect to MongoDB using this command 
```
mongosh --host localhost --port 27017
```

Verify the connection using ``rs.status()``

## Deploy a Replica Set with TLS enabled and available external to K8s

Before deploying the replica set you need to configure TLS, creating the OpenSSL certificate.

For this, you'll need to provision a public domain and subdomain to be used to access the cluster from the internet.

For example, I created the domain ``mongokube.com`` and 3 different subdomains, associated with each node of the replica set, considering the format ``{resourceName}-{podIndex}-repl.mongokube.com``

```
replica-set-tls-0-repl.mongokube.com
replica-set-tls-1-repl.mongokube.com
replica-set-tls-2-repl.mongokube.com
```

Those subdomains, together with the internal POD's addresses, will be used to create the TLS certificates.

The POD's internal address will have the following format: ``<pod-name>.<metadata.name>-svc.<namespace>.svc.cluster.local``. In my example, the internal DNS of the nodes will be as follows:

```
replica-set-tls-0.replica-set-tls-svc.mongodb-operator.svc.cluster.local
replica-set-tls-1.replica-set-tls-svc.mongodb-operator.svc.cluster.local
replica-set-tls-2.replica-set-tls-svc.mongodb-operator.svc.cluster.local
```

With them in hand, we need to configure our ``san.cnf`` file in order to create the OpenSSL certificates. You'll need to change the DNS SANs (Subject Alternative Name) with the ones associated with your external and internal domains.

Once configured, run the following command to generate the certificates:
```
$ openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout tls.key -out tls.crt \
  -config san.cnf \
  -extensions req_ext
```

Convert both certificates to the ``.pem`` format with the ``cp`` command, than run the following command to issue the client certificate and key

```
$ cat tls.crt tls.key > client.pem
```

Now, we need to add the TLS certificates to our K8s namespace. First, set the default namespace of your kubectl to the one of your clusters with the command below.

```
$ kubectl config set-context $(kubectl config current-context) --namespace=<metadata.namespace>
```

Each certificate name must have a prefix, which will be used to configure the Replica Set cluster.

For example, if you call your deployment ``replica-set-tls`` and you set the prefix to ``mdb``, you must name the TLS secret for the client TLS communications ``mdb-replica-set-tls-cert``.

To create the first secret, run the following command, changing the replica-set-tls cert and key to their filepath.

```
$ kubectl create secret tls <prefix>-<metadata.name>-cert \
  --cert=<replica-set-tls-cert> \
  --key=<replica-set-tls-key>
```

Do the same to the agent's TLS certificate

```
$ kubectl create secret tls <prefix>-<metadata.name>-agent-certs \
  --cert=<agent-tls-cert> \
  --key=<agent-tls-key>
```

Next create a Config Map with the Certificate Authority (CA) from the tls.crt file

```
kubectl create configmap custom-ca --from-file=ca-pem=<your-custom-ca-file>
```

Now, change the ``replica-set-tls.yaml`` file with the correct data in order to deploy the cluster. Once done, deploy the replica set with the following command:

```
$	kubectl apply -f replica-set-tls.yaml
```

When finished, you should have 3 new PODs running and 3 external Load Balancers with their respective IP addresses.

To check this, you can run the commands below

```
$ kubectl get services
$ kubectl get pod
```

By having the external IP addresses of the load balancers, you'll be able to configure the subdomains to point to this IPs.

For example, you should configure the subdomain ``replica-set-tls-0-repl.mongokube.com`` to point a ``A`` entrance to the external load balancer IP associated to ``replica-set-tls-0`` POD.

Before connecting to the cluster, you should create a database user using Ops Manager.

Once this is done and the DNS has propagated, you should be able to connect to your Cluster using your external DNS in Compass. For this, when configuring the connection string, you'll need to set the 3 subdomains, your user and add the TLS certificates in the configuration.

## (Optional) Profiler data in the replica set 

This script will generate 1M documents. It will apply a mix of indexes and poorly queries to generae some metrics and recommendations on the [query profiler](https://www.mongodb.com/docs/atlas/tutorial/query-profiler/) and [performance advisor](https://www.mongodb.com/docs/ops-manager/current/reference/api/performance-advisor/).

To run the script, run the following command on the ``/profiler`` folder
```
docker run --network host --mount type=bind,source="$(pwd)/config.json",target=/config.json sylvainchambon/simrunner:latest
```

Note: the port-forwarding needs to be enabled before running the command 


## References

- [MonoDB Enterprise Kubernetes Operator](https://www.mongodb.com/docs/kubernetes-operator/current/)
- [SimRunner](https://github.com/schambon/SimRunner)

## Next steps 

- Enable TLS Certificate
- Support for sharding cluster
- Support for multi-cluster deployments
