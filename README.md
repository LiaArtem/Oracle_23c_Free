# Oracle_23c_Free
Oracle Database 23c Free Developer on Docker Desktop integration with WEB-services (GET,POST - JSON,XML,CSV)
(pipelined, utl_http, json_*, SQL JSON Data Type, xmltable).
Add JSON Relational Duality, JSON Schema, SQL BOOLEAN Data Type.

---------------------------------------------------------------------------------
Встановлення
---------------------------------------------------------------------------------
1) Встановлюємо Docker Desktop
   https://www.docker.com/products/docker-desktop/

2) Створюємо Docker Container
   - виконуємо .\!create_oracle_free.bat
   - буде розгорнуто базу даних з об'єктами.

3) Встановлюємо Oracle Client
   - завантажуємо Oracle Instant Client Basic Package - instantclient-basic-windows.x64-21.9.0.0.0dbru.zip або версію вище
    - https://www.oracle.com/database/technologies/instant-client/winx64-64-downloads.html
   - розпаковуємо в папку c:\oracle\product, якщо її немає, створюємо

   - Змінні середовища -> Системні змінні
     -> Path додаємо строку - c:\oracle\product\instantclient_21_9\
     -> додаємо параметр і значення NLS_LANG = AMERICAN_AMERICA.AL32UTF8

   - завантажуємо SQL*Plus Package - instantclient-sqlplus-windows.x64-21.9.0.0.0dbru.zip
   - розпаковуємо в папку c:\oracle\product\
   - копіюємо файли .\client\tnsnames.ora та .\client\sqlnet.ora в папку c:\oracle\product\instantclient_21_9\network\admin\
   - перевіряємо:
     - cmd
     - sqlplus /nolog
     - connect TEST_USER/!Aa112233@FREE
     - exit

4) Якщо при роботі помилка - ORA-29024: Certificate validation failure, то термін сертифікатів закінчився, потрібні нові сертификати

   - встановлюємо останнього повного клієнта WINDOWS.X64_213000_client.zip або нового, якщо не встановлено
     де є вбудований Oracle Wallet Manager
     https://www.oracle.com/database/technologies/oracle21c-windows-downloads.html
   - після встановлення налаштовуємо глобальний реєстр:
     [HKEY_LOCAL_MACHINE\SOFTWARE\ORACLE\KEY_OraClient21Home1] -> NLS_LANG=AMERICAN_AMERICA.AL32UTF8

   - опис - https://oracle-base.com/articles/misc/utl_http-and-ssl

   - так як у цьому прикладі читаємо web сервіси НБУ і з сайту НАІС беремо з сайтів сертифікати для організації https з'єднання.
   - заходимо через Google Chrome -> https://bank.gov.ua/ -> Тиснемо на замок -> З'єднання безпечне -> Сертифікат дійсний -> Деталі
     -> Експортувати -> ASCII Base64-кодування, цепочка сертифікатів -> _.bank.gov.ua.crt

   - запускаємо Oracle Wallet manager -> New -> (Yes, Yes) -> Password (будь-який, в даному прикладі = 34534kjhsdffkjsdfgalfgb###) -> (No)
     -> Trusted Certificates -> Import Trusted Certificates -> файл _.bank.gov.ua.crt
     -> Закриваємо -> Save -> Шлях C:\wallet, погано створюємо папку wallet або вибираємо інший шлях.
     У папці з'явиться файл ewallet.p12

   - переносимо файл у Docker Container:
     - копіюємо новий файл ewallet.p12 в папку .\wallet\
     - запускаємо .\!update_wallet.bat

   - видаляємо повного клієнта, якщо більше не потрібен

---------------------------------------------------------------------------------
Налаштування та робота з IDE Oracle SQL Developer
---------------------------------------------------------------------------------
   - налаштовуємо кодування із середовищем Oracle SQL Developer та запуск debug
     - Tools -> Preferences -> Environment -> Encoding (змінюємо cp1251 на UTF-8).
   - для Debug:
     - Compile for Debug -> Debug
   - для компіляції помилок:
     - SQL developer -> Recompile Sсhema
   - експорт об'єктів у SQL developer
     - приклад у зображенні - Settings Export object SQL developer.jpg

---------------------------------------------------------------------------------
Загальні SQL
---------------------------------------------------------------------------------
   - об'єкти користувача
   select * from user_objects;
   - інвалідні об'єкти користувача
   select * from user_objects where status != 'VALID'
   - сесії
   select * from V$SESSION;