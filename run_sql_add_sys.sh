#!/bin/bash
sqlplus -s /nolog << EOF
CONNECT sys/!Aa112233 as sysdba;

whenever sqlerror exit sql.sqlcode;
set echo off
set heading off

@/opt/sql/sys/sql_add_sys.sql
@/opt/sql/sys/sql_add_sys_acl_all.sql
@/opt/sql/sys/sql_add_sys_grant_acl_sql_dev.sql

exit;
EOF
