# Deploying Search & Vector Search

## Prerequisites
- A local Kubernetes cluser running
- OpsManager deployed and running
- A replica-set deployed and running
- Database authentication disabled

## Import sample data to the local database

Deploy a `MongoDB Tools Pod` to support importing the data:

```
kubectl apply -f mongodb-tools.yaml
```

Connect to the newly created `mongodb-tools-pod` to execute commands via Shell:

```
kubectl exec -n mongodb-operator -it mongodb-tools-pod -- sh
```

Download the sample data from the internet to the `tmp` folder inside of the pod:

```
curl -fSL https://atlas-education.s3.amazonaws.com/sample_mflix.archive -o /tmp/sample_mflix.archive
```

Import sample data to the local database (replica-set):

```
  mongorestore \
   --host replica-set-svc \
   --port 27017 \
   --archive=/tmp/sample_mflix.archive \
   --nsInclude 'sample_mflix.*'
```

### Verify if the `sample_mflix` database is imported  

To connect to the replica set from outside the Kubernetes cluster, we need to forward the port of the replicaset service:
```
kubectl port-forward -n mongodb-operator svc/replica-set-svc 27017:27017
```

Connect with Compass with the following connection string:
```
mongodb://localhost:27017/admin?authSource=admin&directConnection=true
```

![Alt text](/images/Compass-sample-data.png)
