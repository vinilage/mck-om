# MongoDB, OpsManager and Search locally with MCK 

Using MongoDB Controllers for Kubernetes (MCK) to deploy MongoDB, Ops Manager and Search locally.  
This is an opinionated, non-production tutorial aiming to PoC the main EA components locally.  
Feel free to clone this repo and to apply changes as you prefer.  

## Prerequisities

- [Git](https://git-scm.com/install/) for cloning this repo and execute the commands.
- [MongoDB Shell](https://www.mongodb.com/docs/mongodb-shell/) installed on your local machine.
- [MongoDB Compass](https://www.mongodb.com/products/tools/compass) to connect to the MongoDB Server.
- [Docker](https://www.docker.com/) to manage your containers.
- [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-macos/) to run commands against Kubernetes clusters.
- [K3d](https://k3d.io/stable/) to create local Kubernetes clusters.
- [K9s](https://k9scli.io/) to manage your local clusters (optional but recommended).

### Recommendations
- Docker resource allocation to avoid issues: `Docker -> Settings -> Resources`.  
- Memory limit: at least `15GB`
- CPU limit: `10`

## Summary of what we will do
After installing all the tools, we will:  
- clone this repository in your local machine.
- create a local Kubernetes cluster with K3d.
- add the Helm repository for installing the Operator.
- install the Operator (MCK).
- deploy OpsManager with AppDB (3 members).
- deploy a MongoDB replicaset (3 members) without authentication.
- enable SCRAM authentication in the replica-set.
- create 3 database users: `mdb-admin`, `mdb-user` and `search-sync-source`.
- insert a sample data in your local database .
- deploy `Search` and create Search & Vector Search indexes.
- execute `Search` and `Vector Search` queries.

## Clone this repo in your local machine

The first step is to clone this repository in your local machine in order to have all necessary files.  

```
git clone https://github.com/vinilage/mck-om.git
```

## Setup a local K3d cluster

To spin-up the local K3d cluster, run the following command 

```
k3d cluster create mongodb-mck-cluster
```
This will create a ``mongodb-mck-cluster`` local cluster and it will set the context to it.  
Verify the new cluster by running ``kubectl get nodes`` command or with `k9s`.  


## Install the operator

To install the MongoDB Controllers for Kubernetes (enterprise) run:

```
helm repo add mongodb https://mongodb.github.io/helm-charts
helm repo update
helm install kubernetes-operator mongodb/mongodb-kubernetes --namespace mongodb-operator --create-namespace
```

This will install the latest version of the MCK operator via Helm.  
To verify the installation you can run ``k9s -n mongodb-operator``

## Deploy Ops Manager

Fill your credentials in the ``ops-manager/secret.yaml`` file.  
Put the desired version of Ops Manager and Application Database (AppDB) in the ``ops-manager/deploy.yaml`` 

Then run the following command:

```
kubectl apply -f ./ops-manager/deploy-om.yaml
```  

The deployment may take long (10 minutes or more) since the operator will pull the images of ``AppDB`` and ``OpsManager`` (2GB). Also, OpsManager needs around 5 minutes to start.  

You can verify the on-going deployment by running ``k9s -n mongodb-operator``.  
You will see the pods starting:
- three replicas of AppDB (ops-manager-db) 
- one instance of OpsManager (ops-manager)

### Verification

After around 15 minutes, if you run ``k9s -n mongodb-operator`` you must see:

![Alt text](/images/k9s-after-install.png)

## Accessing OpsManager via browser

If you check all the Kubernetes services, by running ``kubectl get svc -n mongodb-operator`` you will find out that there is a LoadBalancer ``ops-manager-svc-ext`` with EXTERNAL-IP ``<pending>``. This LoadBalancer would provide external access to OpsManager, and we would be able to access it via browser. For simplicitly, we will use port forward to do so. OpsManager is available via ``ops-manager-db-svc`` service via port ``8080`` thus we will forward this. 

Run the following command, and leave it running:

```
kubectl port-forward service/ops-manager-svc 8080:8080 -n mongodb-operator
```  

Now you can access OpsManager, deployed locally with Kubernetes, via browser:

```
http://localhost:8080
```

You will see the login page of OpsManager running in your local Kubernetes cluster.

![Alt text](/images/om-login.png)

### Create a new OM user

If this is your first access with OpsManager, create a new user by clicking in Sign-up.  
Fill all the fields, and you will be redirected to the control panel web-app.

## Next steps...

- [Deploy replica-set](https://github.com/vinilage/mck-om/blob/main/replica-set/README.md)
- [Deploy Search & Vector Search](https://github.com/vinilage/mck-om/blob/main/search/README.md)
- Deploy sharded cluster
- Deploy multi-cluster
- Configure TLS


## References

- Github repo: [ent-mongodb-operator](https://github.com/kamloiic/ent-mongodb-opertor)
- [MonoDB Controllers for Kubernetes](https://www.mongodb.com/docs/kubernetes-operator/current/)

