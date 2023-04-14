#!/bin/bash
sqlplus -s /nolog << EOF
CONNECT TEST_USER/!Aa112233;

whenever sqlerror exit sql.sqlcode;
set echo off
set heading off
set define off

@/opt/sql/table/audit_ddl_change.pdc
@/opt/sql/table/currency.pdc
@/opt/sql/table/fair_value.pdc
@/opt/sql/table/import_data_type.pdc
@/opt/sql/table/isin_secur.pdc
@/opt/sql/table/isin_secur_pay.pdc
@/opt/sql/table/kurs.pdc

@/opt/sql/view/view_kurs_report.pdc

@/opt/sql/type/T_ERB_MINFIN_ROW.tps
@/opt/sql/type/T_ERB_MINFIN_TABLE.tps
@/opt/sql/type/T_FAIR_VALUE_ROW.tps
@/opt/sql/type/T_FAIR_VALUE_TABLE.tps
@/opt/sql/type/T_ISIN_SECUR_ROW.tps
@/opt/sql/type/T_ISIN_SECUR_TABLE.tps
@/opt/sql/type/T_KURS_NBU_ROW.tps
@/opt/sql/type/T_KURS_NBU_TABLE.tps

@/opt/sql/sequence/audit_ddl_change_seq.pdc
@/opt/sql/sequence/kurs_seq.pdc

@/opt/sql/function/EXAMPLE_JSON_ARRAYAGG.fnc

@/opt/sql/procedure/READ_WALLET_PARAM.prc
@/opt/sql/procedure/ADD_IMPORT_DATA_TYPE.prc
@/opt/sql/procedure/EXAMPLE_JSON_DATA_TYPE.prc
@/opt/sql/procedure/INSERT_KURS.prc
@/opt/sql/procedure/HTTP_REQUEST.prc

@/opt/sql/package/P_CHECK.pck
@/opt/sql/package/P_CONVERT.pck
@/opt/sql/package/P_INTERFACE.pck
@/opt/sql/package/P_INTERFACE_PIPE.pck

@/opt/sql/trigger/TR_AUDIT_DDL_CHANGE_BEFORE.trg
@/opt/sql/trigger/TR_AUDIT_DDL_BEFORE.trg

exit;
EOF
