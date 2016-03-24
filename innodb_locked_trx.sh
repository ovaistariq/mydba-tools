#!/bin/bash

mysql -e 'CREATE DATABASE IF NOT EXISTS `test`'

echo "-- creating history table 'test.innodb_lock_history' to record history of blocked and blocking transactions"

echo 'CREATE TABLE `innodb_lock_history` (
  `requesting_trx_id` varchar(18) CHARACTER SET utf8 NOT NULL DEFAULT "",
  `requesting_process_id` bigint(21) unsigned NOT NULL DEFAULT "0",
  `requesting_trx_started` datetime NOT NULL DEFAULT "0000-00-00 00:00:00",
  `requesting_trx_query` varchar(1024) CHARACTER SET utf8 DEFAULT NULL,
  `requesting_wait_started` datetime DEFAULT NULL,
  `blocking_trx_id` varchar(18) CHARACTER SET utf8 NOT NULL DEFAULT "",
  `blocking_process_id` bigint(21) unsigned NOT NULL DEFAULT "0",
  `blocking_trx_started` datetime NOT NULL DEFAULT "0000-00-00 00:00:00",
  `blocking_trx_query` varchar(1024) CHARACTER SET utf8 DEFAULT NULL,
  `blocking_wait_started` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;' | mysql

echo "-- creating view innodb_current_locks"

echo 'CREATE VIEW innodb_current_locks
AS
SELECT requesting_trx_id, r.trx_mysql_thread_id as requesting_process_id,
    r.trx_started as requesting_trx_started, r.trx_query as
requesting_trx_query,
    r.trx_wait_started as requesting_wait_started,
    blocking_trx_id, b.trx_mysql_thread_id as blocking_process_id,
    b.trx_started as blocking_trx_started, b.trx_query as blocking_trx_query,
    b.trx_wait_started as blocking_wait_started
FROM information_schema.INNODB_LOCK_WAITS
INNER JOIN information_schema.INNODB_TRX as r on requesting_trx_id=r.trx_id
INNER JOIN information_schema.INNODB_TRX as b on blocking_trx_id=b.trx_id;' | mysql

echo "-- creating event to maintain history table 'test.innodb_lock_history'"

echo 'CREATE EVENT e_innodb_record_lock_history
   ON SCHEDULE
   EVERY 1 SECOND
COMMENT "Logs InnoDB locking and locked transactions"
DO
   INSERT INTO innodb_lock_history SELECT * FROM innodb_current_locks;' | mysql

echo "-- enabling event scheduler"
mysql -e 'SET GLOBAL event_scheduler=1;'
