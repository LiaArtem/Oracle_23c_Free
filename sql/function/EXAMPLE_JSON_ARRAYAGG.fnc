CREATE OR REPLACE NONEDITIONABLE FUNCTION EXAMPLE_JSON_ARRAYAGG return varchar2
is
  p_rezult varchar2(4000);
begin
/* пример работы с JSON_ARRAYAGG и JSON_OBJECT
{
  "vps": [{
      "ID": 1,
      "rootID": 11,
      "vpNum": 111
    },
    {
      "ID": 2,
      "rootID": 22,
      "vpNum": 222
    }
  ],
  "accountInfo": {
    "identCode": "12345678",
    "lastName": "Прізвище(до 240 сиволів)",
    "firstName": "Ім'я(до 100 сиволів)",
    "middleName": "По батькові(до 100 сиволів)",
    "birthDate": "Дата народження у форматі YYYY-MM-DD",
    "account": "No рахунку(до 34 сиволів)",
    "iban": "IBAN(до 34 сиволів)",
    "currencyCode": "Код валюти (3 символи)",
    "operationType": 1,
    "operationDate": "Дата операції у форматі YYYY-MM-DD"
  },
  "bankInfo": {
    "mfo": "МФО(6 символів)",
    "edrpou": "ЄДРПОУ(8 символів)",
    "name": "Назва банка(до 255 символів)",
    "employee": "Прізвище, ім’я, по батькові відповідальної особи (за наявності, до 255 символів)",
    "phone": "Телефон (за наявності, до 100 символів)"
  }
}

Еще есть объект - JSON_ARRAY
SELECT JSON_ARRAY(first, last) FROM customers;
["Eric","Cartman"]
["Kenny","McCormick"]
*/
    select JSON_OBJECT(
              'vps' value (
                          -- [{"ID":1,"rootID":11,"vpNum":111},{"ID":2,"rootID":22,"vpNum":222}]
                          with acc as (select 1 as ID, 11 as rootID, 111 as vpNum from dual
                                       union
                                       select 2 as ID, 22 as rootID, 222 as vpNum from dual
                                       )
                          select JSON_ARRAYAGG(
                                    JSON_OBJECT('ID' value ID,
                                                'rootID' value rootID,
                                                'vpNum' value vpNum))
                          from acc
                          ),
              'accountInfo' value (JSON_OBJECT( 'identCode' value '12345678',
                                                'lastName' value 'Прізвище(до 240 сиволів)',
                                                'firstName' value 'Ім''я(до 100 сиволів)',
                                                'middleName' value 'По батькові(до 100 сиволів)',
                                                'birthDate' value 'Дата народження у форматі YYYY-MM-DD',
                                                'account' value 'No рахунку(до 34 сиволів)',
                                                'iban' value 'IBAN(до 34 сиволів)',
                                                'currencyCode' value 'Код валюти (3 символи)',
                                                'operationType' value 1,
                                                'operationDate' value 'Дата операції у форматі YYYY-MM-DD'
                                              )),
              'bankInfo' value (JSON_OBJECT( 'mfo' value 'МФО(6 символів)',
                                             'edrpou' value 'ЄДРПОУ(8 символів)',
                                             'name' value 'Назва банка(до 255 символів)',
                                             'employee' value 'Прізвище, ім’я, по батькові відповідальної особи (за наявності, до 255 символів)',
                                             'phone' value 'Телефон (за наявності, до 100 символів)'
                                              ))
                         ) into p_rezult;

    return p_rezult;
end;
/
