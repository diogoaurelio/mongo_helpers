# ReplicaSets & Sharding essentials
These are some notes and scripts on how-tos and best practices regarding ReplicationSets & sharding ops in MongoDB.

###Replication Sets
-----------------------------------------------------

####Sample script
-----------------------------------------------------
A sample script for creating a replication set with 3 nodes locally located in: /scripts/replicaSet.sh


###Sharding
-----------------------------------------------------
Check [manual (in release 3.0.5 is chapter 10 - Sharding](http://docs.mongodb.org/master/MongoDB-manual.pdf) for more details. When starting to shard, some new lego peaces are added to the equation. The key components:
* shards - group of Replication Sets, where one or more collections is distributed (yes, for the time being, sharding is enabled on specific DB and specific collection-level; i.e. does not imply that all DBs/collections will be sharded).
* shard key - a collection is partioned based on the this key, which must be an already created index or compound index that exists in every Document of the DB. MongoDB devides the shard key values into chunks and devides them into chunks
* chunks - a collection enabled for sharding is devided into chunks, which (should) be distrubuted among shards. The way this works depends on how the DB dude sets this, but essentially depends on the shard key chosen.
* mongos - "where the hell is the data?!?" question is answered by these guys, also known as the query routers - are (the new - since mongod is only available for admin ops) interface between Client App and appropriate Shards. there can (and should) be multiple of these guys, usually co-located at the App driver.
* config servers - store metadata of the cluster, which the "mogos" use to know where (the hell) the chunks are located

Sharding can be range-based or hash-based partioning. Hash based are usually a better option, and it guarantees more randomness into the partioning among shards. Range based partioning may yield better performance for range queries, but may result in less distributed data allocation.

####Choosing Shard keys:
-----------------------------------------------------
An important consideration is that Shard Keys are immutable, and thus not changeable after creation. (Glup..)
