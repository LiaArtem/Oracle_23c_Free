CREATE OR REPLACE NONEDITIONABLE PACKAGE P_CHECK
as

    -- Проверка валидности JSON
    function is_valid_json(p_text clob) return boolean;

    -- Проверка валидности XML
    function is_valid_xml(p_text clob) return boolean;

    -- Валидация входящего json с его схемой    
    function is_valid_json_schema (p_text clob, p_type varchar2) return boolean;

end;
/
CREATE OR REPLACE NONEDITIONABLE PACKAGE BODY P_CHECK
as

    -- Проверка валидности JSON
    function is_valid_json(p_text clob) return boolean
    is
      p_is_valid boolean;
    begin
        select decode(count(*),0, false, true) into p_is_valid
        from
        (
        select p_text as t
        ) tt
        where tt.t is json; -- валидация json

        return p_is_valid;
    end;

    -- Проверка валидности XML
    function is_valid_xml(p_text clob) return boolean
    is
        p_xml xmltype;
    begin
        p_xml := xmltype(p_text);
        return true;
    exception when others
    then
        return false;
    end;

    -- Валидация входящего json с его схемой    
    function is_valid_json_schema (p_text clob, p_type varchar2) return boolean 
    is
      m_valid       pls_integer;
      m_schema      varchar2(4000);
    begin 
      -- при генерации через сайт https://www.liquid-technologies.com/online-json-to-schema-converter схемы
      -- после items убрать лишние [ и закрывающую ее ]
      if p_type = 'kurs_nbu'
      then
         m_schema := '{
                      "type": "array",
                      "items": 
                        {
                          "type": "object",
                          "properties": {
                            "r030": {
                              "type": "integer"
                            },
                            "txt": {
                              "type": "string"
                            },
                            "rate": {
                              "type": "number"
                            },
                            "cc": {
                              "type": "string"
                            },
                            "exchangedate": {
                              "type": "string"
                            }
                          },
                          "required": [
                            "r030",
                            "txt",
                            "rate",
                            "cc",
                            "exchangedate"
                          ]
                        }
                     }';
      else
         raise_application_error(-20000, 'Для типа '||p_type||' схема не найдена', true);
      end if;
      
      if is_valid_json(p_text => p_text)  = false
      then
         raise_application_error(-20000, 'Для типа '||p_type||' JSON тело не валидный json', true);        
      end if;

      if is_valid_json(p_text => m_schema)  = false
      then
         raise_application_error(-20000, 'Для типа '||p_type||' JSON схема не валидный json', true);        
      end if;
          
      -- проверяем валидная ли структура схемы
      m_valid := DBMS_JSON_SCHEMA.is_schema_valid(json_data => m_schema);
      if m_valid = 0
      then
         raise_application_error(-20000, 'Для типа '||p_type||' структура JSON схемы содержит ошибки', true);         
      end if;   
      
      m_valid := dbms_json_schema.is_valid(json_data   => json(p_text),
                                           json_schema => json(m_schema));                                            
      if m_valid = 1
      then
         return true;                                      
      end if;   
                  
      return false;
    end;

end;
/
