CREATE OR REPLACE NONEDITIONABLE TRIGGER TR_AUDIT_DDL_BEFORE
before ddl on schema
declare
 -- аудит изменения объектов
 m_osuser        varchar2(255);
 m_mashine       varchar2(4000);
 m_cnt           binary_integer;
 m_hist_cnt      binary_integer;
 m_sql_text      ora_name_list_t;
 type t_string_array is table of varchar2(32000) index by binary_integer;
 m_hist_sql_text t_string_array;
 m_stmt          clob;
 m_hist_stmt     clob;
 m_obj_name      varchar2(255);
 m_obj_type      varchar2(255);
 m_sysevent      varchar2(255);
begin
  -- получаем системные параметры
  m_osuser := substr(sys_context('USERENV','OS_USER'),1,255);
  m_obj_name := upper(ora_dict_obj_name);
  m_obj_type := substr(ora_dict_obj_type,1,255);
  m_sysevent := ora_sysevent;

  m_mashine := substr(sys_context('USERENV','TERMINAL'),1,4000);
  if nvl(m_mashine, 'unknown') = 'unknown'
  then
     m_mashine := substr('HOST=' || sys_context('USERENV','HOST'),1,4000);
  end if;

  -- выдачи прав не протоколируем
  if m_sysevent in ('GRANT','REVOKE')
  then
     return;
  end if;

   m_cnt := ora_sql_txt(m_sql_text);

   if m_cnt is not null
   then
       for i in 1..nvl(m_cnt,0)
       loop
          if i = 1 and m_obj_type in ('PACKAGE','PACKAGE BODY','PROCEDURE','FUNCTION','TRIGGER') and m_sysevent in ('CREATE')
          then
            m_stmt := replace(m_sql_text(i), 'create or replace ');
            m_stmt := replace(m_stmt, upper('create or replace '));
          elsif i = m_cnt
          then
            m_stmt := m_stmt || replace(m_sql_text(i),chr(0));
          else
            m_stmt := m_stmt || m_sql_text(i);
          end if;
       end loop;
   end if;

   -- изменение
   if m_obj_type in ('PACKAGE','PACKAGE BODY','PROCEDURE','FUNCTION','TRIGGER','JAVA','JAVA SOURCE') and m_sysevent in ('CREATE', 'DROP')
   then
     if m_obj_type = 'JAVA' then m_obj_type := 'JAVA SOURCE'; end if;

     select text
     bulk collect into m_hist_sql_text
      from (select s.text
              from user_source s
             where s.name = m_obj_name
               and s.type = m_obj_type
            order by s.line
           );

     m_hist_cnt := m_hist_sql_text.count;

     if m_hist_cnt > 0
     then
        for i in 1..m_hist_cnt
        loop
           m_hist_stmt := m_hist_stmt || m_hist_sql_text(i);
        end loop;
     end if;

     -- если не изменилось выходим
     if dbms_lob.compare(m_stmt, m_hist_stmt) = 0
     then
        return;
     end if;

    insert into audit_ddl_change
     (id,
      object_name,
      object_type,
      osuser,
      osmachine,
      ddl_time,
      action,
      prev_text,
      text
      )
    values
     (audit_ddl_change_seq.nextval,
      m_obj_name,
      m_obj_type,
      m_osuser,
      m_mashine,
      sysdate,
      m_sysevent,
      m_hist_stmt,
      m_stmt
      );

 -- перекомпиляция
 elsif m_obj_type in ('PACKAGE', 'PACKAGE BODY', 'PROCEDURE', 'FUNCTION') and m_sysevent = 'ALTER'
 then
    return;
 else
   -- добавление
    insert into audit_ddl_change
     (id,
      object_name,
      object_type,
      osuser,
      osmachine,
      ddl_time,
      action,
      prev_text,
      text
      )
    values
     (audit_ddl_change_seq.nextval,
      m_obj_name,
      m_obj_type,
      m_osuser,
      m_mashine,
      sysdate,
      m_sysevent,
      null,
      m_stmt
      );
 end if;
end;
/
