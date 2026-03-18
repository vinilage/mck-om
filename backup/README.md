# Enabling Backups - work in progress...

## What we will do

- Deploy an `oplog` replica-set and setup a database user `mdb-user-backup`
- Set an `assignmentLabels` to our current replica-set
- A PVC `snapshot-store-ops-manager` using the local filesystem
- Enable backup in OpsManager

