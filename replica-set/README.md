# Deploy a replica set

**Prerequisities**:  
Kubernetes cluster and MCK ready: [details here](https://github.com/vinilage/mck-om)


## Deploying the replica set

Run the following command in the ``./replica-set`` folder to start deploying the replica-set under a new project.
```
make deploy-rs
```

### Verification
If everything goes well, in OpsManager ``Projects > replica-set > Deployment`` and you will see 3 replicas.
It may take some minutes to have them running, since the binaries will be downloaded.

![Alt text](/images/om-replicaset.png)

In K9s you also should see all the replicaset members up and running:  

![Alt text](/images/replicaset-k9s.png)

To troubleshoot evuentual IP issues, run the following command
```
kubectl describe mdb replica-set -n mongodb-operator 
```

### Connect to the replica set (using port-forward)

To connect to the replica set from outside the Kubernetes cluster, we need to forward the port of the replicaset service:
```
kubectl port-forward -n mongodb-operator svc/replica-set-svc 27017:27017
```

Then you can connect for instance with MongoDB Compass, simply by creating a new connection to localhost.  
At this point, there is no user or password, so the connection string is really only:
```
mongodb://localhost:27017
```

You will see something like this:

![Alt text](/images/compass.png)


## References

- Github repo: [ent-mongodb-operator](https://github.com/kamloiic/ent-mongodb-opertor)
- [MonoDB Controllers for Kubernetes](https://www.mongodb.com/docs/kubernetes-operator/current/)

