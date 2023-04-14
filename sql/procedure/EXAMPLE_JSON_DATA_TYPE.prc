CREATE OR REPLACE NONEDITIONABLE PROCEDURE EXAMPLE_JSON_DATA_TYPE
AS
-- https://oracle-base.com/articles/21c/json_transform-21c

  l_json  json;
  l_obj   json_object_t;

  cursor s
  is
    select json(j.data_n) as data_n
    from import_data_type t,
         json_table(t.data_json, '$[*]' columns data_n format json path '$'  ) j
    where t.id in (select max(tt.id) from import_data_type tt where tt.type_oper = 'kurs_nbu' and tt.data_type = 'json');
BEGIN
  -- Get the JSON data.
  open s;
  fetch s into l_json;
  close s;

  -------------------------------------------------------------
  -- Create a JSON_OBJECT_T object and output the contents.
  -------------------------------------------------------------
  l_obj := json_object_t(l_json);
  dbms_output.put_line('stringify = ' || l_obj.stringify); -- stringify специальный синтаксис

  -------------------------------------------------------------
  -- Convert it back to JSON.
  -------------------------------------------------------------
  l_json := l_obj.to_json;
  dbms_output.put_line('l_json = ' || json_serialize(l_json));

-------------------------------------------------------------
  -- Update the JSON column. - пример
-------------------------------------------------------------
  --  update t1
  --  set    json_data = l_json
  --  where  id = 1;

-------------------------------------------------------------
  -- JSON_TRANSFORM
-------------------------------------------------------------
update import_data_type
set data_json = json_transform(data_json,
                               insert '$[*].updated_date' = systimestamp,
                               set '$[0].rate' = 123.111,
                               rename '$[*].txt' = 'name',
                               rename '$[*].r030' = 'code',
                               rename '$[*].cc' = 'short_name'
                               returning json)
where id in (select max(tt.id) from import_data_type tt where tt.type_oper = 'kurs_nbu' and tt.data_type = 'json');

-------------------------------------------------------------
  -- JSON_TRANSFORM in Oracle Database 21c
  -- SET - устанавливаем существующее значение элемента
     -- Обработчики
     -- REPLACE ON EXISTING (default), ERROR ON EXISTING, IGNORE ON EXISTING
     -- CREATE ON MISSING (default), ERROR ON MISSING, IGNORE ON MISSING
     -- NULL ON NULL (default), ERROR ON NULL, IGNORE ON NULL, REMOVE ON NULL

  -- INSERT - добавляет элемент если не существует
     -- Обработчики
     -- ERROR ON EXISTING (default), IGNORE ON EXISTING, REPLACE ON EXISTING
     -- NULL ON NULL (default), ERROR ON NULL, IGNORE ON NULL, REMOVE ON NULL

  -- APPEND - добавляет элемент в конец массива
     -- Обработчики
     -- ERROR ON MISSING (default), IGNORE ON MISSING, CREATE ON MISSING
     -- NULL ON NULL (default), ERROR ON NULL, IGNORE ON NULL

  -- REMOVE - удаляет элемент
     -- Обработчики
     -- IGNORE ON MISSING (default), ERROR ON MISSING

  -- REPLACE - обновление значений
  -- KEEP - удаления всех элементов, кроме тех, которые включены в список, разделенный запятыми, или пути поиска.

-------------------------------------------------------------
--SET Operation - число
--  select json_transform(json_data,
--                        set '$.quantity' = 20
--                        returning clob pretty) as data
-- from   t1 where  id = 1;

--SET Operation - дата
--  select json_transform(json_data,
--                        set '$.updated_date' = systimestamp
--                        returning clob pretty) as data
-- from   t1 where  id = 1;

--SET Operation - json
--  select json_transform(json_data,
--                        set '$.additional_info' = json('{"colour":"red","size":"large"}')
--                        returning clob pretty) as data
-- from   t1 where  id = 1;

--SET Operation - json
--  select json_transform(json_data,
--                        set '$.additional_info' = '{"colour":"red","size":"large"}' format json
--                        returning clob pretty) as data
-- from   t1 where  id = 1;

--SET Operation - array - обновление 1-го объекта в массиве
--  select json_transform(json_data,
--                        set '$.produce[0].quantity' = 20
--                        returning clob pretty) as data
-- from   t1 where  id = 1;

--SET Operation - array - обновление всех объектов в массиве
--  select json_transform(json_data,
--                        set '$.produce[*].updated_date' = systimestamp
--                        returning clob pretty) as data
-- from   t1 where  id = 1;

--The default behaviour of the SET operation can be altered using the following handlers.
--  select json_transform(json_data,
--                        set '$.updated_date' = systimestamp error on missing
--                        returning clob pretty) as data
-- from   t1 where  id = 1;

--INSERT Operation - число - добавляет если нет
--  select json_transform(json_data,
--                        insert '$.quantity' = 20 error on existing
--                        returning clob pretty) as data
-- from   t1 where  id = 1;

--APPEND Operation
--select json_transform(json_data,
--                      append '$.produce' = JSON('{"fruit":"banana","quantity":20}')
--                      returning clob pretty) as data
--from   t1 where  id = 2;

--select json_transform(json_data,
--                      insert '$.produce[last+1]' = JSON('{"fruit":"banana","quantity":20}')
--                      returning clob pretty) as data
--from   t1 where  id = 2;

--REMOVE Operation
--select json_transform(json_data,
--                      rename '$.fruit' = 'fruit_name'
--                      returning clob pretty) as data
--from   t1 where  id = 1;

--REPLACE Operation
--select json_transform(json_data,
--                      replace '$.quantity' = 20
--                      returning clob pretty) as data
--from   t1 where  id = 1;

--KEEP Operation
--select json_transform(json_data,
--                      keep '$'
--                      returning clob pretty) as data
--from   t1 where  id = 1;

--select json_transform(json_data,
--                      keep '$.fruit', '$.quantity'
--                      returning clob pretty) as data
--from   t1 where  id = 1;

--Combining Multiple Operations
--select json_transform(json_data,
--                      set '$.created_date' = systimestamp,
--                      set '$.updated_date' = systimestamp,
--                      rename '$.fruit' = 'fruit_type',
--                      replace '$.quantity' = 20
--                      returning clob pretty) as data
--from   t1 where  id = 1;

-- Update the data directly in the table.
--update t1
--set    json_data = json_transform(json_data,
--                                  set '$.created_date' = systimestamp,
--                                  set '$.updated_date' = systimestamp,
--                                  rename '$.fruit' = 'fruit_type',
--                                  replace '$.quantity' = 20
--                                  returning json)
--where  id = 1;

END EXAMPLE_JSON_DATA_TYPE;
/
