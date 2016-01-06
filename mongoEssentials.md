# Mongo essentials
These are some notes and scripts on how-tos and best practices regarding MongoDB.

###[Atomicity and Transactions](http://docs.mongodb.org/manual/core/write-operations-atomicity/)

In MongoDB, a write operation is atomic on the level of a single document, even if the operation modifies multiple embedded documents within a single document.

When a single write operation modifies multiple documents, the modification of each document is atomic, but the operation as a whole is not atomic and other operations may interleave. However, you can isolate a single write operation that affects multiple documents using the $isolated operator.

Using the $isolated operator, a write operation that affect multiple documents can prevent other processes from interleaving once the write operation modifies the first document. This ensures that no client sees the changes until the write operation completes or errors out.

Isolated write operation does not provide “all-or-nothing” atomicity. That is, an error during the write operation does not roll back all its changes that preceded the error.

The $isolated operator does not work on sharded clusters.

###Hardware Tips
-----------------------------------------------------
* Generally speaking, choose Faster CPU clock over increase number of cores;
* Disable NUMA on Bios
* 64 Bit systems
* SSD Generally are better; 'wear endurence' problems occur mostly on high sequencial writting, for example using batch jobs such as MapReduce

###General Tips
Can execute javascript scripts through shell like so:
```
mongo --shell myScript.js
```
To shut down a node without connecting to it:
```
var a = connect("hostname:port/admin");
a.shutdownServer()
rs.status()
```
Or connecting to it and:
How to force a shutdown of a member:
```
use admin
db.shutdownServer({force:true})
```
NOTE: force: true - optional


If connected to a secondary node, and you want to issue commands agains collections:
```
rs.slaveOk()
```

Simulations of data insertion. Here is an example of 10 records a second insertion:
```
for(var i = 0; i <= 1000000 ; i++){db.rollback.insert({"a" : i}); sleep(100);}
```

Importing json collections:
```
mongoimport -d databaseName --collection collectionName ./collection.json
```

Drop a collection:
```
use dbName
db.collectionName.drop()
```


###Collections
-----------------------------------------------------

Special kind of collections:
* Capped collections - have a limit of size (pre-allocated max-size), and work in a circular fashion, in the sense that, if reaches the end, it overwrites the first/second/... item(s) to writte a new document (depending on size of new document, it deletes X previous docs); advantage - are faster than normal collections
* TTL collections - auto age out for old documents;


###Indexing
-----------------------------------------------------
Ordered & sorted by default


####Example testing indexes

```javascript
use test;
for (var i = 0; i < 10001; i++){
   db.stuff.insert({a: i, b: 0, c: 0});
   db.stuff.insert({a: 0, b: i, c: 0});
   db.stuff.insert({a: 0, b: 0, c: i});
}

db.stuff.find().length() //3003

//indexes
{
	"createdCollectionAutomatically" : false,
	"numIndexesBefore" : 1,
	"numIndexesAfter" : 2,
	"ok" : 1
}
db.stuff.createIndex({a: 1, c: 1})
/*
{
	"createdCollectionAutomatically" : false,
	"numIndexesBefore" : 2,
	"numIndexesAfter" : 3,
	"ok" : 1
}
*/
db.stuff.createIndex({c: 1})

/*
{
	"createdCollectionAutomatically" : false,
	"numIndexesBefore" : 3,
	"numIndexesAfter" : 4,
	"ok" : 1
}
*/
db.stuff.createIndex({a: 1, b: 1, c: -1})
/*
{
	"createdCollectionAutomatically" : false,
	"numIndexesBefore" : 4,
	"numIndexesAfter" : 5,
	"ok" : 1
}
*/

db.stuff.find({'a':{'$lt':10000}, 'b':{'$gt': 5000}}, {'a':1, 'c':1}).sort({'c':-1}).explain()
```

```javascript
db.albums.aggregate([{$unwind: "$images"}, {$group: {_id: "$images"}}, {$out: "check"}])
show collections
//albums
//check
//images
//system.indexes
db.check.find().pretty()

```


###Handling Write Concern
Here's how to specify write concern on a write from the App:
```javascript
db.foo.insert( { _id : 1 }, { writeConcern : { w : 2 } } )
```


###GridFS
-----------------------------------------------------
Where files stored in MongoDB when you need to go beyong (current) limit of 16MB of BSON document. It is sort of an internal pre-defined spec on how to store large data internally on DB.


## Mongo Memmory Model

- Uses Memory Mapped files to do physical-virtual memmory translation (map())
- Data lazily loaded
- when memory becomes full, uses <b>Least Recently Used algorithm (LRU)</b> to release space for Physical Memmory;
- <b>Working set</b>: portion of Data that is accessed most often (ex: indexes, subset of data, ..)
