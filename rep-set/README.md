# Deploy a replica set

**Prerequisities**:  
Kubernetes cluster and MCK ready: [details here](https://github.com/vinilage/mck-om)


## Deploying the replica set

Run the following command in the ``./rep-set`` folder to start deploying the replica-set under a new project.
```
make deploy-rs
```

### Verification
If everything goes well, in ``Projects > replica-set > Deployment`` and you will see 3 replicas.
It may take some minutes to have them running, since the binaries will be downloaded.

![Alt text](/images/om-replicaset.png)


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

- Github repo: [ent-mongodb-operator](https://github.com/kamloiic/ent-mongodb-opertor)
- [MonoDB Controllers for Kubernetes](https://www.mongodb.com/docs/kubernetes-operator/current/)

