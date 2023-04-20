CREATE OR REPLACE NONEDITIONABLE PACKAGE P_INTERFACE_PIPE
as
    -------------------------------------------------------------------
    type type_fair_value_row is record
    (
     calc_date         date,
     cpcode            varchar2(255),
     ccy               varchar2(3),
     fair_value        number,
     ytm               number,
     clean_rate        number,
     cor_coef          number,
     maturity          date,
     cor_coef_cash     number,
     notional          number,
     avr_rate          number,
     option_value      number,
     intrinsic_value   number,
     time_value        number,
     delta_per         number,
     delta_equ         number,
     dop               varchar2(255)
    );
    type type_fair_value_table is table of type_fair_value_row;
    -------------------------------------------------------------------
    type type_isin_secur_row is record
    (
      cpcode          varchar2(255),
      nominal         integer,
      auk_proc        number,
      pgs_date        date,
      razm_date       date,
      cptype          varchar2(255),
      cpdescr         varchar2(255),
      pay_period      integer,
      val_code        varchar2(3),
      emit_okpo       varchar2(255),
      emit_name       varchar2(255),
      cptype_nkcpfr   varchar2(255),
      cpcode_cfi      varchar2(255),
      total_bonds     integer,
      pay_date        date,
      pay_type        integer,
      pay_val         number,
      pay_array       varchar2(5)
    );
    type type_isin_secur_table is table of type_isin_secur_row;
    -------------------------------------------------------------------
    type type_kurs_nbu_row is record
    (
     r030         varchar2(3),
     txt          varchar2(255),
     rate         number,
     cc           varchar2(3),
     exchangedate date
    );
    type type_kurs_nbu_table is table of type_kurs_nbu_row;
    -------------------------------------------------------------------
    type type_erb_minfin_row is record
    (
     isSuccess       varchar2(5),
     num_rows        integer,
     requestDate     date,
     isOverflow      varchar2(5),
     num_id          number,
     root_id         number,
     lastname        varchar2(4000),
     firstname       varchar2(4000),
     middlename      varchar2(4000),
     birthdate       varchar2(255),
     publisher       varchar2(4000),
     departmentcode  varchar2(4000),
     departmentname  varchar2(4000),
     departmentphone varchar2(4000),
     executor        varchar2(4000),
     executorphone   varchar2(4000),
     executoremail   varchar2(4000),
     deductiontype   varchar2(4000),
     vpnum           varchar2(4000),
     okpo            varchar2(255),
     full_name       varchar2(4000)
    );
    type type_erb_minfin_table is table of type_erb_minfin_row;

    -- Справедливая стоимость ЦБ (котировки НБУ)
    -- Получить данные
    -- select f.* from table (p_interface_pipe.read_fair_value(p_date => to_date('09.04.2021','dd.mm.yyyy'))) f;
    function read_fair_value (p_date date) -- дата
      return type_fair_value_table pipelined;

    -- Перечень ISIN ЦБ с купонными периодами
    -- Получить данные
    -- select f.* from table (p_interface_pipe.read_isin_secur(p_format => 'json')) f;
    function read_isin_secur (p_format varchar2) -- формат xml, json
      return type_isin_secur_table pipelined;

    -- Курсы валют НБУ
    -- Получить данные
    -- select f.* from table (p_interface_pipe.read_kurs_nbu(p_date => to_date('09.04.2021','dd.mm.yyyy'), p_format => 'json', p_currency => 'USD')) f;
    function read_kurs_nbu (p_date date, -- дата курсов
                            p_format varchar2, -- формат xml, json
                            p_currency varchar2 default null -- UAH, USD, EUR
                            ) return type_kurs_nbu_table pipelined;

    -- НАИС - поиск контрагента в ЕРД (едином реестре должников)
    -- Получить данные
    -- select f.* from table (p_interface_pipe.read_erb_minfin(p_identCode => '33270581', p_type_cust_code => '2')) f;
    -- select f.* from table (p_interface_pipe.read_erb_minfin(p_identCode => '2985108376', p_type_cust_code => '1')) f;
    -- select f.* from table (p_interface_pipe.read_erb_minfin(p_lastName       => 'Бондарчук',
    --                                                         p_firstName      => 'Ігор',
    --                                                         p_middleName     => 'Володимирович',
    --                                                         p_birthDate      => to_date('23.09.1981','dd.mm.yyyy'),
    --                                                         p_type_cust_code => '1')) f;
    function read_erb_minfin (p_categoryCode   varchar2 default null, -- пусто все, 03 - аллименты
                              p_identCode      varchar2 default null,
                              p_lastName       varchar2 default null,
                              p_firstName      varchar2 default null,
                              p_middleName     varchar2 default null,
                              p_birthDate      date     default null,
                              p_type_cust_code varchar2 -- (1 - физ., 2 - юр.)
                              ) return type_erb_minfin_table pipelined;


   -- Справедливая стоимость ЦБ (котировки НБУ)
   procedure add_fair_value (p_date date);

   -- Курсы валют НБУ
   procedure add_kurs_nbu (p_date date, p_currency_code varchar2);

   -- Перечень ISIN ЦБ с купонными периодами
   procedure add_isin_secur;

end;
/
CREATE OR REPLACE NONEDITIONABLE PACKAGE BODY P_INTERFACE_PIPE
as

    -- Справедливая стоимость ЦБ (котировки НБУ)
    -- Получить данные
    -- select f.* from table (p_interface_pipe.read_fair_value(p_date => to_date('09.04.2021','dd.mm.yyyy'))) f
    function read_fair_value (p_date date) -- дата
      return type_fair_value_table pipelined
    is
      p_url                  varchar2(255);
      p_wallet_file          varchar2(255);
      p_wallet_file_pwd      varchar2(255);
      p_response_body        clob;
      p_response_status_code integer;
      p_response_status_desc varchar2(7000);
      p_fair_value_row       type_fair_value_row;
    begin
      p_url := 'https://bank.gov.ua/files/Fair_value/'||to_char(p_date,'yyyymm/yyyymmdd')||'_fv.txt';

      read_wallet_param(p_wallet_file => p_wallet_file, p_wallet_file_pwd => p_wallet_file_pwd);

      -- запрашиваем данные
      http_request(p_url => p_url,
                   p_url_method => 'GET',
                   p_header_body_charset => 'WINDOWS-1251',
                   p_wallet_file => p_wallet_file,
                   p_wallet_file_pwd => p_wallet_file_pwd,
                   p_transfer_timeout => 60,
                   p_response_body => p_response_body,
                   p_response_status_code => p_response_status_code,
                   p_response_status_desc => p_response_status_desc);

      if p_response_status_code = -100
      then
         raise_application_error(-20000, p_response_status_desc, true);
      end if;

      --dbms_output.put_line(p_response_body);

      -- добавить историю
      ADD_IMPORT_DATA_TYPE(p_type_oper => 'fair_value', p_data_type => 'csv', p_data_value => p_response_body);

      for j in (
                with tt as (select p_response_body || chr(13)||chr(10) as str from dual)
                select regexp_substr(str, '[^'||chr(13)||chr(10)||']+', 1, level) as string_row, rownum as num
                from tt
                connect by nvl(regexp_instr(str, '[^'||chr(13)||chr(10)||']+', 1, level), 0) <> 0
                )
      loop
          -- заголовок пропускаем
          if j.num = 1 then continue; end if;

          for k in (
                    with tt as (select j.string_row || ';' as str from dual)
                    select p_convert.str_to_date(regexp_substr(str, '[^;]+', 1, 1)) as calc_date,
                           regexp_substr(str, '[^;]+', 1, 2) as cpcode,
                           regexp_substr(str, '[^;]+', 1, 3) as ccy,
                           p_convert.str_to_num(regexp_substr(str, '[^;]+', 1, 4)) as fair_value,
                           p_convert.str_to_num(regexp_substr(str, '[^;]+', 1, 5)) as ytm,
                           p_convert.str_to_num(regexp_substr(str, '[^;]+', 1, 6)) as clean_rate,
                           p_convert.str_to_num(regexp_substr(str, '[^;]+', 1, 7)) as cor_coef,
                           p_convert.str_to_date(regexp_substr(str, '[^;]+', 1, 8)) as maturity,
                           p_convert.str_to_num(regexp_substr(str, '[^;]+', 1, 9)) as cor_coef_cash,
                           p_convert.str_to_num(regexp_substr(str, '[^;]+', 1, 10)) as notional,
                           p_convert.str_to_num(regexp_substr(str, '[^;]+', 1, 11)) as avr_rate,
                           p_convert.str_to_num(regexp_substr(str, '[^;]+', 1, 12)) as option_value,
                           p_convert.str_to_num(regexp_substr(str, '[^;]+', 1, 13)) as intrinsic_value,
                           p_convert.str_to_num(regexp_substr(str, '[^;]+', 1, 14)) as time_value,
                           p_convert.str_to_num(regexp_substr(str, '[^;]+', 1, 15)) as delta_per,
                           p_convert.str_to_num(regexp_substr(str, '[^;]+', 1, 16)) as delta_equ,
                           regexp_substr(str, '[^;]+', 1, 17) as dop
                    from tt
                    )
           loop
              p_fair_value_row.calc_date := k.calc_date;
              p_fair_value_row.cpcode := k.cpcode;
              p_fair_value_row.ccy := k.ccy;
              p_fair_value_row.fair_value := k.fair_value;
              p_fair_value_row.ytm := k.ytm;
              p_fair_value_row.clean_rate := k.clean_rate;
              p_fair_value_row.cor_coef := k.cor_coef;
              p_fair_value_row.maturity := k.maturity;
              p_fair_value_row.cor_coef_cash := k.cor_coef_cash;
              p_fair_value_row.notional := k.notional;
              p_fair_value_row.avr_rate := k.avr_rate;
              p_fair_value_row.option_value := k.option_value;
              p_fair_value_row.intrinsic_value := k.intrinsic_value;
              p_fair_value_row.time_value := k.time_value;
              p_fair_value_row.delta_per := k.delta_per;
              p_fair_value_row.delta_equ := k.delta_equ;
              p_fair_value_row.dop := k.dop;
              pipe row(p_fair_value_row);
           end loop;
       end loop;

       return;
    end;

    -- Перечень ISIN ЦБ с купонными периодами
    -- Получить данные
    -- select f.* from table (p_interface.read_isin_secur(p_format => 'json')) f;
    function read_isin_secur (p_format varchar2) -- формат xml, json
      return type_isin_secur_table pipelined
    is
      p_url                  varchar2(255);
      p_wallet_file          varchar2(255);
      p_wallet_file_pwd      varchar2(255);
      p_response_body        clob;
      p_response_status_code integer;
      p_response_status_desc varchar2(7000);
      p_dop_param            varchar2(5);
      p_isin_secur_row       type_isin_secur_row;
    begin
      if p_format = 'json' then p_dop_param := '?json'; end if;
      p_url := 'https://bank.gov.ua/depo_securities'||p_dop_param;

      read_wallet_param(p_wallet_file => p_wallet_file, p_wallet_file_pwd => p_wallet_file_pwd);

      -- запрашиваем данные
      http_request(p_url => p_url,
                   p_url_method => 'GET',
                   p_header_content_type => case when p_format = 'json' then 'application/json' else 'text/xml' end,
                   p_wallet_file => p_wallet_file,
                   p_wallet_file_pwd => p_wallet_file_pwd,
                   p_transfer_timeout => 60,
                   p_response_body => p_response_body,
                   p_response_status_code => p_response_status_code,
                   p_response_status_desc => p_response_status_desc);

      if p_response_status_code = -100
      then
         raise_application_error(-20000, p_response_status_desc, true);
      end if;

       --dbms_output.put_line(p_response_body);
      -- добавить историю
      ADD_IMPORT_DATA_TYPE(p_type_oper => 'isin_secur', p_data_type => p_format, p_data_value => p_response_body);

       if p_format = 'json'
       then
          if p_check.is_valid_json(p_response_body) = true
          then
              for k in (
                       select t.cpcode,
                              t.nominal,
                              p_convert.str_to_num(t.auk_proc) as auk_proc,
                              p_convert.str_to_date(t.pgs_date,'yyyy-mm-dd') as pgs_date,
                              p_convert.str_to_date(t.razm_date,'yyyy-mm-dd') as razm_date,
                              t.cptype,
                              t.cpdescr,
                              t.pay_period,
                              t.val_code,
                              t.emit_okpo,
                              t.emit_name,
                              t.cptype_nkcpfr,
                              t.cpcode_cfi,
                              t.total_bonds,
                              t.payments
                          from json_table(p_response_body, '$[*]'
                                           columns
                                              cpcode          varchar2(255) path '$.cpcode',
                                              nominal         integer       path '$.nominal',
                                              auk_proc        varchar2(255) path '$.auk_proc',
                                              pgs_date        varchar2(255) path '$.pgs_date',
                                              razm_date       varchar2(255) path '$.razm_date',
                                              cptype          varchar2(255) path '$.cptype',
                                              cpdescr         varchar2(255) path '$.cpdescr',
                                              pay_period      integer       path '$.pay_period',
                                              val_code        varchar2(3)   path '$.val_code',
                                              emit_okpo       varchar2(255) path '$.emit_okpo',
                                              emit_name       varchar2(255) path '$.emit_name',
                                              cptype_nkcpfr   varchar2(255) path '$.cptype_nkcpfr',
                                              cpcode_cfi      varchar2(255) path '$.cpcode_cfi',
                                              total_bonds     integer       path '$.pay_period',
                                              payments        FORMAT JSON   path '$.payments'
                                            ) t
                         )
               loop
                  if k.payments is null
                  then
                      p_isin_secur_row.cpcode := k.cpcode;
                      p_isin_secur_row.nominal := k.nominal;
                      p_isin_secur_row.auk_proc := k.auk_proc;
                      p_isin_secur_row.pgs_date := k.pgs_date;
                      p_isin_secur_row.razm_date := k.razm_date;
                      p_isin_secur_row.cptype := k.cptype;
                      p_isin_secur_row.cpdescr := k.cpdescr;
                      p_isin_secur_row.pay_period := k.pay_period;
                      p_isin_secur_row.val_code := k.val_code;
                      p_isin_secur_row.emit_okpo := k.emit_okpo;
                      p_isin_secur_row.emit_name := k.emit_name;
                      p_isin_secur_row.cptype_nkcpfr := k.cptype_nkcpfr;
                      p_isin_secur_row.cpcode_cfi := k.cpcode_cfi;
                      p_isin_secur_row.total_bonds := k.total_bonds;
                      p_isin_secur_row.pay_date := null;
                      p_isin_secur_row.pay_type := null;
                      p_isin_secur_row.pay_val := null;
                      p_isin_secur_row.pay_array := null;
                      pipe row(p_isin_secur_row);
                  else
                      -- периоды
                      for kk in (
                                 select p_convert.str_to_date(t.pay_date,'yyyy-mm-dd') as pay_date,
                                        t.pay_type,
                                        p_convert.str_to_num(t.pay_val) as pay_val,
                                        t.pay_array
                                    from json_table(k.payments, '$[*]'
                                                     columns
                                                        pay_date        varchar2(255) path '$.pay_date',
                                                        pay_type        integer       path '$.pay_type',
                                                        pay_val         varchar2(255) path '$.pay_val',
                                                        pay_array       varchar2(255) path '$.array'
                                                      ) t
                                )
                      loop
                          p_isin_secur_row.cpcode := k.cpcode;
                          p_isin_secur_row.nominal := k.nominal;
                          p_isin_secur_row.auk_proc := k.auk_proc;
                          p_isin_secur_row.pgs_date := k.pgs_date;
                          p_isin_secur_row.razm_date := k.razm_date;
                          p_isin_secur_row.cptype := k.cptype;
                          p_isin_secur_row.cpdescr := k.cpdescr;
                          p_isin_secur_row.pay_period := k.pay_period;
                          p_isin_secur_row.val_code := k.val_code;
                          p_isin_secur_row.emit_okpo := k.emit_okpo;
                          p_isin_secur_row.emit_name := k.emit_name;
                          p_isin_secur_row.cptype_nkcpfr := k.cptype_nkcpfr;
                          p_isin_secur_row.cpcode_cfi := k.cpcode_cfi;
                          p_isin_secur_row.total_bonds := k.total_bonds;
                          p_isin_secur_row.pay_date := kk.pay_date;
                          p_isin_secur_row.pay_type := kk.pay_type;
                          p_isin_secur_row.pay_val := kk.pay_val;
                          p_isin_secur_row.pay_array := kk.pay_array;
                          pipe row(p_isin_secur_row);
                      end loop;
                   end if;
               end loop;
           end if;
       else
          if p_check.is_valid_xml(p_response_body) = true
          then
              for k in (
                       select t.cpcode,
                              t.nominal,
                              p_convert.str_to_num(t.auk_proc) as auk_proc,
                              p_convert.str_to_date(t.pgs_date,'yyyy-mm-dd') as pgs_date,
                              p_convert.str_to_date(t.razm_date,'yyyy-mm-dd') as razm_date,
                              t.cptype,
                              t.cpdescr,
                              t.pay_period,
                              t.val_code,
                              t.emit_okpo,
                              t.emit_name,
                              t.cptype_nkcpfr,
                              t.cpcode_cfi,
                              t.total_bonds,
                              t.payments
                          from xmltable('//security' passing xmltype(p_response_body)
                                           columns
                                              cpcode          varchar2(255) path 'cpcode',
                                              nominal         integer       path 'nominal',
                                              auk_proc        varchar2(255) path 'auk_proc',
                                              pgs_date        varchar2(255) path 'pgs_date',
                                              razm_date       varchar2(255) path 'razm_date',
                                              cptype          varchar2(255) path 'cptype',
                                              cpdescr         varchar2(255) path 'cpdescr',
                                              pay_period      integer       path 'pay_period',
                                              val_code        varchar2(3)   path 'val_code',
                                              emit_okpo       varchar2(255) path 'emit_okpo',
                                              emit_name       varchar2(255) path 'emit_name',
                                              cptype_nkcpfr   varchar2(255) path 'cptype_nkcpfr',
                                              cpcode_cfi      varchar2(255) path 'cpcode_cfi',
                                              total_bonds     integer       path 'pay_period',
                                              payments        xmltype       path 'payments'
                                            ) t
                         )
               loop
                  if k.payments is null
                  then
                      p_isin_secur_row.cpcode := k.cpcode;
                      p_isin_secur_row.nominal := k.nominal;
                      p_isin_secur_row.auk_proc := k.auk_proc;
                      p_isin_secur_row.pgs_date := k.pgs_date;
                      p_isin_secur_row.razm_date := k.razm_date;
                      p_isin_secur_row.cptype := k.cptype;
                      p_isin_secur_row.cpdescr := k.cpdescr;
                      p_isin_secur_row.pay_period := k.pay_period;
                      p_isin_secur_row.val_code := k.val_code;
                      p_isin_secur_row.emit_okpo := k.emit_okpo;
                      p_isin_secur_row.emit_name := k.emit_name;
                      p_isin_secur_row.cptype_nkcpfr := k.cptype_nkcpfr;
                      p_isin_secur_row.cpcode_cfi := k.cpcode_cfi;
                      p_isin_secur_row.total_bonds := k.total_bonds;
                      p_isin_secur_row.pay_date := null;
                      p_isin_secur_row.pay_type := null;
                      p_isin_secur_row.pay_val := null;
                      p_isin_secur_row.pay_array := null;
                      pipe row(p_isin_secur_row);
                  else
                      -- периоды
                      for kk in (
                                 select p_convert.str_to_date(t.pay_date,'yyyy-mm-dd') as pay_date,
                                        t.pay_type,
                                        p_convert.str_to_num(t.pay_val) as pay_val,
                                        t.pay_array
                                    from xmltable('//payment' passing k.payments
                                                     columns
                                                        pay_date        varchar2(255) path 'pay_date',
                                                        pay_type        integer       path 'pay_type',
                                                        pay_val         varchar2(255) path 'pay_val',
                                                        pay_array       varchar2(255) path 'array'
                                                      ) t
                                )
                      loop
                          p_isin_secur_row.cpcode := k.cpcode;
                          p_isin_secur_row.nominal := k.nominal;
                          p_isin_secur_row.auk_proc := k.auk_proc;
                          p_isin_secur_row.pgs_date := k.pgs_date;
                          p_isin_secur_row.razm_date := k.razm_date;
                          p_isin_secur_row.cptype := k.cptype;
                          p_isin_secur_row.cpdescr := k.cpdescr;
                          p_isin_secur_row.pay_period := k.pay_period;
                          p_isin_secur_row.val_code := k.val_code;
                          p_isin_secur_row.emit_okpo := k.emit_okpo;
                          p_isin_secur_row.emit_name := k.emit_name;
                          p_isin_secur_row.cptype_nkcpfr := k.cptype_nkcpfr;
                          p_isin_secur_row.cpcode_cfi := k.cpcode_cfi;
                          p_isin_secur_row.total_bonds := k.total_bonds;
                          p_isin_secur_row.pay_date := kk.pay_date;
                          p_isin_secur_row.pay_type := kk.pay_type;
                          p_isin_secur_row.pay_val := kk.pay_val;
                          p_isin_secur_row.pay_array := kk.pay_array;
                          pipe row(p_isin_secur_row);
                      end loop;
                   end if;
               end loop;
           end if;
       end if;

       return;
    end;

    -- Курсы валют НБУ
    -- Получить данные
    -- select f.* from table (p_interface_pipe.read_kurs_nbu(p_date => to_date('09.04.2021','dd.mm.yyyy'), p_format => 'json', p_currency => 'USD')) f;
    function read_kurs_nbu (p_date date, -- дата курсов
                            p_format varchar2, -- формат xml, json
                            p_currency varchar2 default null -- UAH, USD, EUR
                            ) return type_kurs_nbu_table pipelined
    is
      p_url                  varchar2(255);
      p_wallet_file          varchar2(255);
      p_wallet_file_pwd      varchar2(255);
      p_response_body        clob;
      p_response_status_code integer;
      p_response_status_desc varchar2(7000);
      p_dop_param            varchar2(5);
      p_kurs_nbu_row         type_kurs_nbu_row;
    begin
      if p_format = 'json' then p_dop_param := '&json'; end if;

      if p_currency is null
      then
         p_url := 'https://bank.gov.ua/NBUStatService/v1/statdirectory/exchange?date='||to_char(p_date,'yyyymmdd')||p_dop_param;
      else
         p_url := 'https://bank.gov.ua/NBUStatService/v1/statdirectory/exchange?valcode='||p_currency||'&date='||to_char(p_date,'yyyymmdd')||p_dop_param;
      end if;

      read_wallet_param(p_wallet_file => p_wallet_file, p_wallet_file_pwd => p_wallet_file_pwd);

      -- запрашиваем данные
      http_request(p_url => p_url,
                   p_url_method => 'GET',
                   p_header_content_type => case when p_format = 'json' then 'application/json' else 'text/xml' end,
                   p_wallet_file => p_wallet_file,
                   p_wallet_file_pwd => p_wallet_file_pwd,
                   p_transfer_timeout => 60,
                   p_response_body => p_response_body,
                   p_response_status_code => p_response_status_code,
                   p_response_status_desc => p_response_status_desc);

      if p_response_status_code = -100
      then
         raise_application_error(-20000, p_response_status_desc, true);
      end if;

       --dbms_output.put_line(p_response_body);
      -- добавить историю
      ADD_IMPORT_DATA_TYPE(p_type_oper => 'kurs_nbu', p_data_type => p_format, p_data_value => p_response_body);

       if p_format = 'json'
       then
          if p_check.is_valid_json(p_response_body) = true
          then
              if p_check.is_valid_json_schema(p_text => p_response_body, p_type => 'kurs_nbu') = false
              then
                 raise_application_error(-20000, 'Нарушена структура схемы JSON', true);                         
              end if;    
                                         
              for k in (
                        select lpad(j.r030,3,'0') as r030,
                               j.txt,
                               p_convert.str_to_num(j.rate) as rate,
                               j.cc,
                               p_convert.str_to_date(j.exchangedate) as exchangedate
                          from json_table(p_response_body, '$[*]'
                                 columns (
                                         r030 varchar2(3)   path '$.r030',
                                         txt  varchar2(255) path '$.txt',
                                         rate varchar2(255) path '$.rate',
                                         cc   varchar2(255) path '$.cc',
                                         exchangedate varchar2(255) path '$.exchangedate'
                                         )) j
                         where j.r030 is not null and
                               j.txt  is not null and
                               j.rate is not null and
                               j.cc   is not null and
                               j.exchangedate is not null
                         )
               loop
                  p_kurs_nbu_row.r030 := k.r030;
                  p_kurs_nbu_row.txt := k.txt;
                  p_kurs_nbu_row.rate := k.rate;
                  p_kurs_nbu_row.cc := k.cc;
                  p_kurs_nbu_row.exchangedate := k.exchangedate;
                  pipe row(p_kurs_nbu_row);
               end loop;
           end if;
       else
          if p_check.is_valid_xml(p_response_body) = true
          then
              for k in (
                        select lpad(j.r030,3,'0') as r030,
                               j.txt,
                               p_convert.str_to_num(j.rate) as rate,
                               j.cc,
                               p_convert.str_to_date(j.exchangedate) as exchangedate
                          from xmltable('//exchange/currency' passing xmltype(p_response_body)
                                 columns
                                         r030 varchar2(3)   path 'r030',
                                         txt  varchar2(255) path 'txt',
                                         rate varchar2(255) path 'rate',
                                         cc   varchar2(255) path 'cc',
                                         exchangedate varchar2(255) path 'exchangedate'
                                         ) j
                         where j.r030 is not null and
                               j.txt  is not null and
                               j.rate is not null and
                               j.cc   is not null and
                               j.exchangedate is not null
                         )
               loop
                  p_kurs_nbu_row.r030 := k.r030;
                  p_kurs_nbu_row.txt := k.txt;
                  p_kurs_nbu_row.rate := k.rate;
                  p_kurs_nbu_row.cc := k.cc;
                  p_kurs_nbu_row.exchangedate := k.exchangedate;
                  pipe row(p_kurs_nbu_row);
               end loop;
           end if;
       end if;

       return;
    end;

    -- НАИС - поиск контрагента в ЕРД (едином реестре должников)
    -- Получить данные
    -- select f.* from table (p_interface_pipe.read_erb_minfin(p_identCode => '33270581', p_type_cust_code => '2')) f;
    -- select f.* from table (p_interface_pipe.read_erb_minfin(p_identCode => '2985108376', p_type_cust_code => '1')) f;
    -- select f.* from table (p_interface_pipe.read_erb_minfin(p_lastName       => 'Бондарчук',
    --                                                         p_firstName      => 'Ігор',
    --                                                         p_middleName     => 'Володимирович',
    --                                                         p_birthDate      => to_date('23.09.1981','dd.mm.yyyy'),
    --                                                         p_type_cust_code => '1')) f;
    function read_erb_minfin (p_categoryCode   varchar2 default null, -- пусто все, 03 - аллименты
                              p_identCode      varchar2 default null,
                              p_lastName       varchar2 default null,
                              p_firstName      varchar2 default null,
                              p_middleName     varchar2 default null,
                              p_birthDate      date     default null,
                              p_type_cust_code varchar2 -- (1 - физ., 2 - юр.)
                              ) return type_erb_minfin_table pipelined
    is
      p_url                  varchar2(255);
      p_wallet_file          varchar2(255);
      p_wallet_file_pwd      varchar2(255);
      p_response_body        clob;
      p_response_status_code integer;
      p_response_status_desc varchar2(7000);
      p_type_erb_minfin_row  type_erb_minfin_row;
      p_request_body         clob;
    begin
      p_url := 'https://erb.minjust.gov.ua/listDebtorsEndpoint';

      -- физ. лица
      if p_type_cust_code = '1'
      then
          select to_clob(JSON_OBJECT('searchType' value '1',
                             'paging'     value '1',
                             'filter'     value JSON_OBJECT('LastName'     value p_convert.screening_json(p_convert.convert_str(p_lastName,'UTF8','CL8MSWIN1251')),
                                                            'FirstName'    value p_convert.screening_json(p_convert.convert_str(p_firstName,'UTF8','CL8MSWIN1251')),
                                                            'MiddleName'   value p_convert.screening_json(p_convert.convert_str(p_middleName,'UTF8','CL8MSWIN1251')),
                                                            'BirthDate'    value case when p_birthDate is null then null
                                                                                      else to_char(p_birthDate,'YYYY-MM-DD')||'T00:00:00.000Z'
                                                                                 end,
                                                            'IdentCode'    value p_identCode,
                                                            'categoryCode' value p_categoryCode
                                                            --absent on null -- если будет пустая переменная, тег не подставляется
                                                            null on null -- по умолчанию, если пустая передается null, можно не прописывать
                                                       )
                            )
                       ) into p_request_body
          from dual;
      else
      -- юр. лица
          select to_clob(JSON_OBJECT('searchType' value '2', 'paging': '1',
                             'filter'     value JSON_OBJECT('FirmName'     value p_convert.screening_json(p_convert.convert_str(p_lastName,'UTF8','CL8MSWIN1251')),
                                                            'FirmEdrpou'   value p_identCode,
                                                            'categoryCode' value p_categoryCode
                                                       )
                            )
                       ) into p_request_body
          from dual;
      end if;

      read_wallet_param(p_wallet_file => p_wallet_file, p_wallet_file_pwd => p_wallet_file_pwd);

      -- запрашиваем данные
      http_request(p_url => p_url,
                   p_url_method => 'POST',
                   p_header_content_type => 'json',
                   p_wallet_file => p_wallet_file,
                   p_wallet_file_pwd => p_wallet_file_pwd,
                   p_transfer_timeout => 60,
                   p_header_body_charset => 'WINDOWS-1251',
                   p_request_body => p_request_body,
                   p_response_body => p_response_body,
                   p_response_status_code => p_response_status_code,
                   p_response_status_desc => p_response_status_desc);

      if p_response_status_code = -100
      then
         raise_application_error(-20000, p_response_status_desc, true);
      end if;

       --dbms_output.put_line(p_request_body);
       --dbms_output.put_line(p_response_body);
       --raise_application_error(-20000, p_request_body, true);
       --raise_application_error(-20000, p_response_body, true);

       -- добавить историю
       ADD_IMPORT_DATA_TYPE(p_type_oper => 'erb_minfin', p_data_type => 'json', p_data_value => p_response_body);

       if json_value(p_response_body,'$.errMsg') is not null
       then
          raise_application_error(-20000, p_request_body||chr(13)||chr(10)||json_value(p_response_body,'$.errMsg'), true);
       end if;

      if p_check.is_valid_json(p_response_body) = true
      then
          p_type_erb_minfin_row.isSuccess := json_value(p_response_body,'$.isSuccess');
          p_type_erb_minfin_row.num_rows := json_value(p_response_body,'$.rows');
          p_type_erb_minfin_row.requestDate := p_convert.get_datetime(json_value(p_response_body,'$.requestDate'));
          p_type_erb_minfin_row.isOverflow := json_value(p_response_body,'$.isOverflow');

          if p_type_erb_minfin_row.num_rows > 0
          then
                for k in (
                          select t.num_id,
                                 t.root_id,
                                 p_convert.convert_str(t.lastname,'CL8MSWIN1251','UTF8') as lastname,
                                 p_convert.convert_str(t.firstname,'CL8MSWIN1251','UTF8') as firstname,
                                 p_convert.convert_str(t.middlename,'CL8MSWIN1251','UTF8') as middlename,
                                 trunc(p_convert.get_datetime(t.birthdate)) as birthdate,
                                 p_convert.convert_str(t.publisher,'CL8MSWIN1251','UTF8') as publisher,
                                 p_convert.convert_str(t.departmentcode,'CL8MSWIN1251','UTF8') as departmentcode,
                                 p_convert.convert_str(t.departmentname,'CL8MSWIN1251','UTF8') as departmentname,
                                 p_convert.convert_str(t.departmentphone,'CL8MSWIN1251','UTF8') as departmentphone,
                                 p_convert.convert_str(t.executor,'CL8MSWIN1251','UTF8') as executor,
                                 p_convert.convert_str(t.executorphone,'CL8MSWIN1251','UTF8') as executorphone,
                                 p_convert.convert_str(t.executoremail,'CL8MSWIN1251','UTF8') as executoremail,
                                 p_convert.convert_str(t.deductiontype,'CL8MSWIN1251','UTF8') as deductiontype,
                                 p_convert.convert_str(t.vpnum,'CL8MSWIN1251','UTF8') as vpnum,
                                 p_convert.convert_str(t.okpo,'CL8MSWIN1251','UTF8') as okpo,
                                 p_convert.convert_str(t.full_name,'CL8MSWIN1251','UTF8') as full_name
                            from json_table(p_response_body, '$.results[*]'
                                   columns (
                                            num_id              number         path '$.ID',
                                            root_id             number         path '$.rootID',
                                            lastname            varchar2(4000) path '$.lastName',
                                            firstname           varchar2(4000) path '$.firstName',
                                            middlename          varchar2(4000) path '$.middleName',
                                            birthdate           varchar2(255)  path '$.birthDate',
                                            publisher           varchar2(4000) path '$.publisher',
                                            departmentcode      varchar2(4000) path '$.departmentCode',
                                            departmentname      varchar2(4000) path '$.departmentName',
                                            departmentphone     varchar2(4000) path '$.departmentPhone',
                                            executor            varchar2(4000) path '$.executor',
                                            executorphone       varchar2(4000) path '$.executorPhone',
                                            executoremail       varchar2(4000) path '$.executorEmail',
                                            deductiontype       varchar2(4000) path '$.deductionType',
                                            vpnum               varchar2(4000) path '$.vpNum',
                                            okpo                varchar2(255)  path '$.code',
                                            full_name           varchar2(4000) path '$.name'
                                           )) t
                        )
                 loop
                    p_type_erb_minfin_row.num_id          := k.num_id;
                    p_type_erb_minfin_row.root_id         := k.root_id;
                    p_type_erb_minfin_row.lastname        := k.lastname;
                    p_type_erb_minfin_row.firstname       := k.firstname;
                    p_type_erb_minfin_row.middlename      := k.middlename;
                    p_type_erb_minfin_row.birthdate       := k.birthdate;
                    p_type_erb_minfin_row.publisher       := k.publisher;
                    p_type_erb_minfin_row.departmentcode  := k.departmentcode;
                    p_type_erb_minfin_row.departmentname  := k.departmentname;
                    p_type_erb_minfin_row.departmentphone := k.departmentphone;
                    p_type_erb_minfin_row.executor        := k.executor;
                    p_type_erb_minfin_row.executorphone   := k.executorphone;
                    p_type_erb_minfin_row.executoremail   := k.executoremail;
                    p_type_erb_minfin_row.deductiontype   := k.deductiontype;
                    p_type_erb_minfin_row.vpnum           := k.vpnum;
                    p_type_erb_minfin_row.okpo            := k.okpo;
                    p_type_erb_minfin_row.full_name       := k.full_name;
                    pipe row(p_type_erb_minfin_row);
                 end loop;
           else
              pipe row(p_type_erb_minfin_row);
           end if;
       end if;

       return;
    end;

   -- Справедливая стоимость ЦБ (котировки НБУ)
   procedure add_fair_value (p_date date)
   is
   begin
      insert into FAIR_VALUE(CALC_DATE,
                             ISIN,
                             CURRENCY_CODE,
                             FAIR_VALUE,
                             YTM,
                             CLEAN_RATE,
                             COR_COEF,
                             MATURITY,
                             COR_COEF_CASH,
                             NOTIONAL,
                             AVR_RATE,
                             OPTION_VALUE,
                             INTRINSIC_VALUE,
                             TIME_VALUE,
                             DELTA_PER,
                             DELTA_EQU,
                             DOP
                             )
            select f.* from table (read_fair_value(p_date => p_date)) f
            where not exists (select 1 from FAIR_VALUE fv where fv.calc_date = f.calc_date and fv.isin = f.cpcode and fv.currency_code = f.ccy)
            ;
   end;

   -- Курсы валют НБУ
   procedure add_kurs_nbu (p_date date, p_currency_code varchar2)
   is
   begin
      insert into CURRENCY(CODE, NAME, SHORT_NAME)
         select f.r030, f.txt, f.cc
         from table (read_kurs_nbu(p_date => p_date, p_format => 'json', p_currency => p_currency_code)) f
         where not exists (select 1 from CURRENCY cc where cc.code = f.r030);

      insert into KURS(ID, KURS_DATE, CURRENCY_CODE, RATE, IS_PRIMARY)
            select kurs_seq.nextval, f.exchangedate, f.cc, f.rate, decode(f.cc, 'USD', true, false)
            from table (read_kurs_nbu(p_date => p_date, p_format => 'json', p_currency => p_currency_code)) f
            where not exists (select 1 from KURS k where k.kurs_date = f.exchangedate and k.currency_code = f.cc)
            ;
   end;

   -- Перечень ISIN ЦБ с купонными периодами
   procedure add_isin_secur
   is
   begin
        -- ЦБ
        insert into ISIN_SECUR(ISIN,
                               NOMINAL,
                               AUK_PROC,
                               PGS_DATE,
                               RAZM_DATE,
                               CPTYPE,
                               CPDESCR,
                               PAY_PERIOD,
                               CURRENCY_CODE,
                               EMIT_OKPO,
                               EMIT_NAME,
                               CPTYPE_NKCPFR,
                               CPCODE_CFI,
                               TOTAL_BONDS
                               )
         select distinct
                f.CPCODE,
                f.NOMINAL,
                f.AUK_PROC,
                f.PGS_DATE,
                f.RAZM_DATE,
                f.CPTYPE,
                f.CPDESCR,
                f.PAY_PERIOD,
                f.VAL_CODE,
                f.EMIT_OKPO,
                f.EMIT_NAME,
                f.CPTYPE_NKCPFR,
                f.CPCODE_CFI,
                f.TOTAL_BONDS
         from table (read_isin_secur(p_format => 'json')) f
         where not exists (select 1 from ISIN_SECUR sec where sec.isin = f.cpcode);

         -- купонные периоды
         insert into ISIN_SECUR_PAY(ISIN_SECUR_ID,
                                    PAY_DATE,
                                    PAY_TYPE,
                                    PAY_VAL)
         select sec.id,
                f.PAY_DATE,
                f.PAY_TYPE,
                f.PAY_VAL
         from table (read_isin_secur(p_format => 'json')) f,
              ISIN_SECUR sec
         where sec.isin = f.cpcode and
               not exists (select 1 from ISIN_SECUR_PAY pay where pay.PAY_DATE = f.PAY_DATE and pay.PAY_TYPE = f.PAY_TYPE and pay.ISIN_SECUR_ID = sec.id);
     end;

end;
/
