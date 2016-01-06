# Backups & restore essentials
These are some notes and scripts on how-tos and best practices regarding integrating backups & restores with MongoDB.

###Backups basics
-----------------------------------------------------
Different options on how to do backups:
* mongodump
* filesystem snapshot
* backup from secondary (shutdown, copy files, restart)

Using mongodump have to use mongorestore utility to restore later. The oplog option allows later to repeat oplog on restore.
```
mongodump --oplog
```

Restore if oplog specified when taking the dump
```
mongorestore --oplogReplay
```

###[Restoring](http://docs.mongodb.org/master/tutorial/restore-replica-set-from-backup/)
-----------------------------------------------------
In a sharded env, for config server restore through mongorestore (so mongodump was used before)
```
mongorestore --port XXXXX -d config  .\config\
```
For other servers:
```
mongorestore --port XXXXX -d nameOfDb  .\dumpDataFiles\
```

To use filesystem snapshoting (LVM, or SAN-enabled) journalling needs to be enabled. Journal directory is usually empty if shutdown of mongo is done cleanly; only on crash does it leave file, and Snapshot (SS) needs to include Journal!
If using for example LVMs with different underlying disks, there may inconsistencies between data on underlying disks. Thus for there cases, you can use db.fsyncLock() - which guarantees flushing of data to disk, freeze writes, so that SS can be done
```
db.fsyncLock()
db.fsyncUnlock()
```



###Backing up Sharded Environment
-----------------------------------------------------
It gets a bit more complicated with Sharded Environments, as you have to guarantee backup of both Replica Sets of each Shard + Config Servers (where meta-data about chuncks is stored)
Important steps to keep in mind while backing up Sharded clusters env:
 * 1) Turn off the balancer (to guarantee no chunck migration occurs)
 ```
 mongo --host dnsname --eval sh.stopBalancer()
 ```
 * 2) Backup config DB (on config server)
 ```
 mongodump --host dnsname --db config
 ```
 * 3) backup each shard's replSet (only one member of each shard)
 ```
 mongodump --host dnsname --oplog /path/to/dump
 ```

 * 4) Start balancer back up again
 ```
 sh.startBalancer()
 ```

[Restoring Sharded Env](http://docs.mongodb.org/master/tutorial/restore-sharded-cluster/)
