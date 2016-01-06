# Security essentials
These are some notes and scripts on how-tos and best practices regarding security in MongoDB.

###Useful resources
-----------------------------------------------------
* [Security Manual](https://docs.mongodb.org/manual/security/)

###Intro
-----------------------------------------------------
Main Aspects to consider regarding security:
* authentication { mongoDB challenge/response, X.509/SSL, Kerberos/LDAP (just for Enterprise Edition) }
* access control/authorization
* encryption

There are 2 main modes:
1) trusted environment - where access is locked down only based on network layer (relevant tcp ports), i.e client Apps and users are able to access Mongo as long as they have Network access
2) mongodb auth - In this mode, 3 additional options can be set: --auth | --keyFile | --ssl
* --auth option for client auth, and RBAC
* --keyFile for certificate based Authentication intra-cluster, and passwords are passed encrypted (works with mongod and mongos);
* --ssl option of using SSL for encrypting all communications, all data shared among mongod instances

Basic way to setup mongo security on:
```
mongod --auth
```
Then, from localhost you will be able to login without authentication at first time to mongo. Then connect to admin db, which has a system.users collection for DBAs use
```
mongo
use admin
var newAdmin = { user: 'adminName', pwd: 'adminPwd', roles: [ ' userAdminAnyDatabase'] }
db.createUser(newAdmin);
```

After this, all other commands will not work, because haven't authenticated yet. Exit mongo, and reconnect with Auth:
```
mongo localhost/admin -u adminName -p
#or
mongo --host localhost --db admin -u adminName -p
```
And enter the password. this user does not have privillages to check other collections out, only Administration tasks, such as creating new users. To add more admin users, can be for example like this:
```
use admin
db.addUser("secAdmin", "secPwd");
```

After this, the admin can create a new user with r/w permissions for all databases:
```
var newUser = { user: 'newUser', pwd: 'userPwd', roles: [ "readWriteAnyDatabase" ] }
```
Note: if this user loggs in, he will not have permissions to create new users, of course, since he's not Admin.
If you want to limit the access a user has to a given DB, as an Admin switch to that DB, and then create new user object:
```
user testDB
var newUser2 = { user: 'newUser2', pwd: 'userPwd', roles: [ "readWrite" ] }
```
Note that this user will only be able to connect as such:
```
mongo localhost/testDB -u newUser2 -p
```
He may even switch to another DB (the prompt currently will not throw immediately any error), but then all commands he tries to perform on the DB will fail.

So Roles are the following:
* read | readAnyDatabase
* readWrite | readWriteAnyDatabase
* dbAdmin | dbAdminAnyDatabase
* userAdmin | userAdminAnyDatabase
* clusterAdmin (for adding replica sets, adding shards, etc)

Note that you can, after logging in with a specific user, access for example admin BD, by "re-auth" without exiting, like so:
```
db.auth("admin", "adminPwd")
```
Checking out existing users:
```
use testDB
db.system.users.find().pretty()
```


###2 security modes
-----------------------------------------------------
