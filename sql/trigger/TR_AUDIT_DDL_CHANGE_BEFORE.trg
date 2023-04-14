CREATE OR REPLACE NONEDITIONABLE TRIGGER TR_AUDIT_DDL_CHANGE_BEFORE before update or delete
ON audit_ddl_change
referencing old as old new as new
for each row
declare
begin
  raise_application_error(-20000, 'Запрещено модифицировать таблицу аудита AUDIT_DDL_CHANGE');
end;
/
