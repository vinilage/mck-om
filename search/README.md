# Deploying Search & Vector Search

## Prerequisites
If you've followed [these steps](https://github.com/vinilage/mck-om/tree/main) you are good to go!
- A local Kubernetes cluster 
- OpsManager deployed
- A replica-set deployed 
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

### Create a Search index

Connect to the `mongodb-tools-pod`:
```
kubectl exec -n mongodb-operator -it mongodb-tools-pod -- sh
```

Find the primary member of the replica-set in OpsManager to build the connection string:  

![Alt text](/images/om-finding-primary.png)

Connect to the primary member of the MongoDB Database to have `write` access:
```
mongosh replica-set-0.replica-set-svc.mongodb-operator.svc.cluster.local
```

Prepare to create the search index inside of the `sample_mflix` database:
```
use sample_mflix
```

Create a `Vector Search` index in the `embedded_movies` collection:
```
db.embedded_movies.createSearchIndex("vector_index", "vectorSearch",
    { "fields": [ {
      "type": "vector",
      "path": "plot_embedding_voyage_3_large",
      "numDimensions": 2048,
      "similarity":
      "dotProduct",
      "quantization": "scalar"
    } ] });
```

Create a `Search` index in the `movies` collection:
```
db.movies.createSearchIndex("default", { mappings: { dynamic: true } });
``` 