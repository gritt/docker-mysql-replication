#!/bin/bash

BASE_PATH=$(dirname $0)

echo "[ ] - waiting mysql"
sleep 60
echo "[v]"

echo "[ ] - stopping mysql on slave"
mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e 'STOP SLAVE;';
mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e 'RESET SLAVE ALL;';
echo "[v]"

echo "[ ] - grant replication to $MYSQL_REPLICATION_USER in $MYSQL_MASTER_ADDRESS"

mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "CREATE USER '$MYSQL_REPLICATION_USER'@'%';"
mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "GRANT REPLICATION SLAVE ON *.* TO '$MYSQL_REPLICATION_USER'@'%' IDENTIFIED BY '$MYSQL_REPLICATION_PASSWORD';"
mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e 'flush privileges;'
echo "[v]"





echo "[ ] - set slave to replicate master"
MYSQL01_Position=$(eval "mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -e 'show master status \G' | grep Position | sed -n -e 's/^.*: //p'")
MYSQL01_File=$(eval "mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -e 'show master status \G'     | grep File     | sed -n -e 's/^.*: //p'")

mysql --host database -uroot -p$MYSQL_ROOT_PASSWORD -AN -e "CHANGE MASTER TO master_host='$MYSQL_MASTER_ADDRESS', master_port=3306, \
        master_user='$MYSQL_REPLICATION_USER', master_password='$MYSQL_REPLICATION_PASSWORD', master_log_file='$MYSQL01_File', \
        master_log_pos=$MYSQL01_Position;"
echo "[v]"





echo "[ ] set master to replicate slave"
MYSQL02_Position=$(eval "mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -e 'show master status \G' | grep Position | sed -n -e 's/^.*: //p'")
MYSQL02_File=$(eval "mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -e 'show master status \G'     | grep File     | sed -n -e 's/^.*: //p'")

mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e "CHANGE MASTER TO master_host='$MYSQL_SLAVE_ADDRESS', master_port=3306, \
        master_user='$MYSQL_REPLICATION_USER', master_password='$MYSQL_REPLICATION_PASSWORD', master_log_file='$MYSQL02_File', \
        master_log_pos=$MYSQL02_Position;"
echo "[v]"





echo "[ ] - start slave on both servers"
mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e "start slave;"
echo "[v]"

echo "[ ] = increase the max_connections to 2000"
mysql --host $MYSQL_MASTER_ADDRESS -uroot -p$MYSQL_MASTER_ROOT_PASSWORD -AN -e 'set GLOBAL max_connections=2000';
mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -AN -e 'set GLOBAL max_connections=2000';
echo "[v]"

mysql --host database -uroot -p$MYSQL_SLAVE_ROOT_PASSWORD -e "show slave status \G"

echo "MySQL servers configured!"
echo "--------------------"
echo
echo MYSQL_MASTER       : $MYSQL_MASTER_ADDRESS
echo MYSQL_SLAVE        : $MYSQL_SLAVE_ADDRESS