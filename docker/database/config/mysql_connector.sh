#!/bin/bash

BASE_PATH=$(dirname $0)


echo "waiting MYSQL.."
sleep 60


echo "stopping slave in SLAVE MYSQL"
mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "stop slave;";
mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "reset slave all;";


#echo "stopping slave in MASTER MYSQL"
#mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "stop slave;";
#mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "reset slave all;";


echo "creating replication user in MASTER MYSQL"
mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "create user '$MYSQL_REPLICATION_USER'@'%';"
mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "grant replication slave on *.* to '$MYSQL_REPLICATION_USER'@'%' identified by '$MYSQL_REPLICATION_PASSWORD';"
mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "flush privileges;"


#echo "creating replication user in SLAVE MYSQL"
#mysql --host $MYSQL_SLAVE_ADDRESS -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "create user '$MYSQL_REPLICATION_USER'@'%';"
#mysql --host $MYSQL_SLAVE_ADDRESS -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "grant replication slave on *.* to '$MYSQL_REPLICATION_USER'@'%' identified by '$MYSQL_REPLICATION_PASSWORD';"
#mysql --host $MYSQL_SLAVE_ADDRESS -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "flush privileges;"


echo "getting MASTER MYSQL config"
Master_Position="$(mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -e 'show master status \G' | grep Position | grep -o '[0-9]*')"
Master_File="$(mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -e 'show master status \G' | grep File | sed -n -e 's/^.*: //p')"


#echo "getting SLAVE MYSQL config"
#Slave_Position="$(mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -e 'show master status \G' | grep Position | grep -o '[0-9]*')"
#Slave_File="$(mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -e 'show master status \G' | grep File | sed -n -e 's/^.*: //p')"


echo "set SLAVE to upstream MASTER"
mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "change master to master_host='$MYSQL_MASTER_ADDRESS',master_user='$MYSQL_REPLICATION_USER',master_password='$MYSQL_REPLICATION_PASSWORD',master_log_file='$Master_File',master_log_pos=$Master_Position;"


#echo "set MASTER to upstream SLAVE"
#mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e"change master to master_host='$MYSQL_SLAVE_ADDRESS',master_user='$MYSQL_REPLICATION_USER',master_password='$MYSQL_REPLICATION_PASSWORD',master_log_file='$Slave_File',master_log_pos=$Slave_Position;"


echo "start sync: MASTER to SLAVE"
mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "start slave;"
mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -e "show slave status \G;"


#echo "start sync: SLAVE to MASTER"
#mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "start slave;"
#mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -e "show slave status \G;"


echo "mysql fine tuning and extra conf"


echo "increasing connection limit"
mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "set GLOBAL max_connections=2000;"
mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "set GLOBAL max_connections=2000;"


echo "disabling sql_mode = ONLY_FULL_GROUP_BY"
mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));"
mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));"

