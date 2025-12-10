# Create MongoDB Database Users
In order secure tthe connection to the databases, we will create 3 database users.  
The manifest files in this folder creates the necessary MongoDB Database users and secrets.  
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


### Verification

You can check in OpsManager if all users were created properly: `Deployment -> replica-set -> Security`

![Alt text](/images/om-users.png)