# Enable SCRUM and create MongoDB database users
What we will do:
- Enable SCRUM authentication in the replica-set deployment
- Create 3 users to secure the access to the database.
- Cretae 3 Kubernetes secrets with the user passwords. 

The passwords are by default `12345678` and the secrets are created to store them.  

### The users are:

- `mdb-admin` have full access to all databases.
- `mdb-user` read and write access only to the `sample_mflix` database, for Vector Search.
- `search-sync-source` mandatory for Search, used between `mongot`  and `mongod`.

### Enable SCRUM Authentication in replica-set
Go to the folder `./user/` and run:
```
kubectl apply -f replica-set-auth.yaml
```

### Create the database users
Go to the folder `./user/` and run:
```
kubectl apply -f admin.yaml -f user.yaml -f search-sync.yaml
```


## Verification

You can check in OpsManager if all users were created properly: `Deployment -> replica-set -> Security`

![Alt text](/images/om-users.png)

### Connect to the replica set (using port-forward)

To connect to the replica set from outside the Kubernetes cluster, we need to forward the port of the replicaset service:
```
kubectl port-forward -n mongodb-operator svc/replica-set-svc 27017:27017
```

Then you can connect for instance with MongoDB Compass, simply by creating a new connection to localhost.  
Now, the user `mdb-admin` and its password `12345678` is used:
```
mongodb://mdb-admin:12345678@localhost:27017/admin?authSource=admin&directConnection=true
```

You will see something like this:
![Alt text](/images/compass.png)

## Continue...
- [Deploy Search & Vector Search](https://github.com/vinilage/mck-om/blob/main/search/README.md)