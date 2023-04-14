CREATE OR REPLACE NONEDITIONABLE PROCEDURE ADD_IMPORT_DATA_TYPE (
       p_type_oper varchar2,
       p_data_type varchar2,
       p_data_value clob
       )
AS
  PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
      -- добавить историю данных
      if p_data_type = 'csv'
      then
         insert into import_data_type(type_oper, data_type, data_clob)
           values (p_type_oper, p_data_type, p_data_value);
      elsif p_data_type = 'xml'
      then
         insert into import_data_type(type_oper, data_type, data_xml)
           values (p_type_oper, p_data_type, xmltype(p_data_value));

      elsif p_data_type = 'json'
      then
         insert into import_data_type(type_oper, data_type, data_json, data_json_old)
           values (p_type_oper, p_data_type, json(p_data_value), p_data_value);

      end if;

      commit;

--exception when others
--then
   --raise_application_error(-20000, p_data_value, true);

END ADD_IMPORT_DATA_TYPE;
/
