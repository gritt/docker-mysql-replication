# Docker MySQL Replication

A simple docker setup to add replication feature to MySQL.

You can choose between topologies by switching branches:

	topology/master-master
	topology/master-slave

Is expected that you have two physically different servers capable of running docker, each server will run a MySQL container, that’s why the 3306 port is exposed in the .env file, you can set either an external IP address (default port should be changed), or, an internal IP address if you have both servers in the same network.

## Master to Slave

The most common topology, Master to Slave, perform ‘reads’ and ‘writes’ on the Master instance and can only perform ‘reads’ in the slave instance, when a entry is created / updated in the Master instance it reflects the changes to the Slave instance.

## Master to Master

The Master to Master topology enables to perform ‘reads’ and ‘writes’ in both servers, created and updated entries are reflected in both ways, thus, extra care must be taken on the application side to avoid duplicated primary keys; if somehow both servers create the same key at the same time, when they sync with each other, it will fail (by configuration) and the servers will no longer be able to perform ‘writes’ until the issue is solved.

#### Open Source

Fell free to use, fork, open issues or pull request with improvements and bug fixes.
