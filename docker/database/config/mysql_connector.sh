#!/bin/bash

BASE_PATH=$(dirname $0)

echo "waiting mysql"
sleep 60


echo "stopping mysql slaves"
mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e"stop slave;";
mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e"reset slave all;";

mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e"reset slave all;";
mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e"reset slave all;";


echo "creating replication user"
mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e"create user '$MYSQL_REPLICATION_USER'@'%';"
mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e"grant replication slave on *.* to '$MYSQL_REPLICATION_USER'@'%' identified by '$MYSQL_REPLICATION_PASSWORD';"
mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e"flush privileges;"


mysql --host $MYSQL_SLAVE_ADDRESS -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e"create user '$MYSQL_REPLICATION_USER'@'%';"
mysql --host $MYSQL_SLAVE_ADDRESS -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e"grant replication slave on *.* to '$MYSQL_REPLICATION_USER'@'%' identified by '$MYSQL_REPLICATION_PASSWORD';"
mysql --host $MYSQL_SLAVE_ADDRESS -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e"flush privileges;"



#MYSQL01_Position=$(eval "mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -e 'show master status \G' | grep Position | sed -n -e 's/^.*: //p'")
#MYSQL01_File=$(eval "mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -e 'show master status \G'     | grep File     | sed -n -e 's/^.*: //p'")

#MYSQL02_Position=$(eval "mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -e 'show master status \G' | grep Position | sed -n -e 's/^.*: //p'")
#MYSQL02_File=$(eval "mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -e 'show master status \G'     | grep File     | sed -n -e 's/^.*: //p'")


echo "sync master to slave"
mysql --host database -uroot -p$MYSQL_ROOT_PASSWORD -AN -e"change master to master_host='$MYSQL_MASTER_ADDRESS',master_user='$MYSQL_REPLICATION_USER',master_password='$MYSQL_REPLICATION_PASSWORD',master_log_file='mysql-bin.000003',master_log_pos=827;"


echo "sync slave to master"
mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e"change master to master_host='$MYSQL_SLAVE_ADDRESS',master_user='$MYSQL_REPLICATION_USER',master_password='$MYSQL_REPLICATION_PASSWORD',master_log_file='mysql-bin.000003',master_log_pos=827;"


echo "start sync: master to slave"
mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e"start slave;"
mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e"show slave status \G;"


echo "start sync: slave to master"
mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e"start slave;"
mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e"show slave status \G;"



#echo "[ ] = increase the max_connections to 2000"
#mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e 'set GLOBAL max_connections=2000';
#mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e 'set GLOBAL max_connections=2000';