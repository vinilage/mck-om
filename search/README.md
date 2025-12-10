# Deploying Search & Vector Search

## Prerequisites
If you've followed [these steps](https://github.com/vinilage/mck-om/tree/main) you are good to go!
- [A local Kubernetes cluster](https://github.com/vinilage/mck-om/tree/main) 
- [OpsManager deployed](https://github.com/vinilage/mck-om/tree/main)
- [A replica-set deployed](https://github.com/vinilage/mck-om/blob/main/replica-set/README.md) 
- [SCRUM authentication enabled and database users created](https://github.com/vinilage/mck-om/blob/main/user/README.md)

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
   --username mdb-admin \
   --password 12345678 \
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
mongodb://admin:12345678@localhost:27017/admin?authSource=admin&directConnection=true
```

![Alt text](/images/Compass-sample-data.png)

### Create a Search index

Connect to the `mongodb-tools-pod`:
```
kubectl exec -n mongodb-operator -it mongodb-tools-pod -- sh
```

Find the primary member of the replica-set in OpsManager to build the connection string:  

![Alt text](/images/om-finding-primary.png)

Connect to the primary member of the MongoDB Database (to be able to `write`) and with `admin` user:
```
mongosh \
  --username mdb-admin \
  --password 12345678 \
  --authenticationDatabase admin \
  "mongodb://replica-set-0.replica-set-svc.mongodb-operator.svc.cluster.local"
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

## Verify the indexes

You can verify if the indexes were created for Search:
```
db.runCommand({"listSearchIndexes": "movies"});
````

or Vector Search:
```
db.runCommand({"listSearchIndexes": "embedded_movies"});
```

## Verify with Compass
With `Compass` you can also see the search indexes `if you are connected to the primary member`.  
You can check if you are connected to the primary by opening the MongoDB Shell in Compass.  
You should see `Enterprise replica-set [direct: primary] admin >`.  

If you see `secondary`, forward the port directly to the primary (check in OM what is your primary).  
Example would be:

```
kubectl port-forward pod/replica-set-0 27017:27017 -n mongodb-operator
```

The indexes should be visible in Compass:  

![Alt text](/images/compass-search-index.png)