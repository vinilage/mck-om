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

## References

[MonoDB Enterprise Kubernetes Operator](https://www.mongodb.com/docs/kubernetes-operator/current/)
