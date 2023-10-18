CREATE OR REPLACE NONEDITIONABLE PACKAGE P_CONVERT
as

  m_userenv varchar2(100) := userenv('language');
  m_base_charset varchar2(50) := substr(m_userenv, instr(m_userenv, '.', 1, 1) + 1,  length(m_userenv));

  -- Преобразование из base64 (до 32000 символов)
  function base64_decode(p_value varchar2) return varchar2;

  -- Преобразование из base64 (clob)
  function base64_decode_clob(p_payload_clob clob) return clob;

  -- Преобразование в base64 (до 32000 символов)
  function base64_encode(p_value varchar2) return varchar2;

  -- Преобразование в base64 (clob)
  function base64_encode_clob(p_payload_clob clob) return clob;

  -- Преобразование суммы в текст (с валютой)
  function str_amount_curr (p_amount     number,
                            p_curr_code  varchar2 default 'UAH',
                            p_is_decimal char default 'F')
    return varchar2;

  -- Преобразование суммы в текст
  function str_amount (p_amount number, p_is_default char := 'T') return varchar2;

  -- Преобразование суммы в текстовый формат числа
  function str_amount_format (p_number number, p_count_comma pls_integer default 2) return varchar2;

  -- Преобразование процента с тест (0,5678999% (нуль цiлих i п'ять мiльйонiв шiстсот сiмдесят вiсiм тисяч дев'ятсот дев'яносто дев'ять десятимільйонних процента))
  function str_interest (p_amount number) return varchar2;

  -- Преобразование теста с UTF8 в базовую кодировку Oracle (до 4000 символов)
  function get_charset_utf8(p_text varchar2) return varchar2;

  -- Преобразование теста с базовую кодировки Oracle в UTF8 (до 4000 символов)
  function to_charset_utf8(p_text varchar2) return varchar2;

   -- Экранирование символов для JSON с доп. конвертацией в UTF8
  function screening_json(p_str in varchar2, p_is_convert_utf8 varchar2 default 'F') return varchar2;

  -- Преобразование теста с число
  function str_to_num (p_text in varchar2) return number;

  -- Преобразование теста в дату
  function str_to_date (p_text in varchar2, p_format in VARCHAR2 default 'dd.mm.yyyy') return date;

  -- Преобразование числа в тест
  function num_to_str (p_amount number) return varchar2;

  -- Преобразование теста из одной в другую кодировку
  -- 'UTF8','CL8MSWIN1251'
  function convert_str(p_text          varchar2,
                       p_char_set_to   varchar2, -- преобразовать в
                       p_char_set_from varchar2 default null) -- преобразования из
    return varchar2;

  -- Преобразование теста в дату и время (формат YYYY-MM-DDThh24:mi:ssZ)
  function get_datetime(p_text varchar2) return date;

  -- Описание (дні)
  function str_days (p_value integer) return varchar2;
  
  -- Описание (місяці)
  function str_month (p_value integer) return varchar2;
    
end;
/
CREATE OR REPLACE NONEDITIONABLE PACKAGE BODY P_CONVERT
as

  -- Преобразование из base64 (до 32000 символов)
  function base64_decode(p_value varchar2) return varchar2
  is
  begin
    if p_value is null then return null; end if;
    return utl_raw.cast_to_varchar2(utl_encode.base64_decode(utl_raw.cast_to_raw(p_value)));
  end;

  -- Преобразование из base64 (clob)
  function base64_decode_clob(p_payload_clob clob) return clob
  is
    m_send_payload_temp clob;
    m_send_payload      clob;
    m_buffer            pls_integer := 8184;
    m_data              varchar2(32736);
    m_len               pls_integer;
    m_start             pls_integer := 1;
  begin
    m_len := dbms_lob.getlength(p_payload_clob);
    if m_len > 0 then
       dbms_lob.createtemporary(m_send_payload_temp, true);
       if m_len < m_buffer then
          m_send_payload_temp := base64_decode(p_payload_clob);
       else
          for i in 1..ceil(m_len / m_buffer)
          loop
            m_data := dbms_lob.substr(p_payload_clob, m_buffer, m_start);
            m_data := base64_decode(m_data);
            dbms_lob.writeappend(m_send_payload_temp, length(m_data), m_data);
            m_start := m_start + m_buffer;
          end loop;
       end if;

       m_send_payload := m_send_payload_temp;
       dbms_lob.freetemporary(lob_loc => m_send_payload_temp);
    end if;
    return m_send_payload;
  end;

  -- Преобразование в base64 (до 32000 символов)
  function base64_encode(p_value varchar2) return varchar2
  is
    m_result varchar2(32736);
  begin
    if p_value is null then return null; end if;
    m_result := utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(p_value)));
    m_result := replace(m_result, chr(13)||chr(10), '');

    return m_result;
  end;

  -- Преобразование в base64 (clob)
  function base64_encode_clob(p_payload_clob clob) return clob
  is
    m_send_payload_temp clob;
    m_send_payload      clob;
    m_buffer            pls_integer := 8184;
    m_data              varchar2(32736);
    m_len               pls_integer;
    m_start             pls_integer := 1;
  begin
    m_len := dbms_lob.getlength(p_payload_clob);
    if m_len > 0 then
       dbms_lob.createtemporary(m_send_payload_temp, true);
       if m_len < m_buffer then
          m_send_payload_temp := base64_encode(p_payload_clob);
       else
          for i in 1..ceil(m_len / m_buffer)
          loop
            m_data := dbms_lob.substr(p_payload_clob, m_buffer, m_start);
            m_data := base64_encode(m_data);
            dbms_lob.writeappend(m_send_payload_temp, length(m_data), m_data);
            m_start := m_start + m_buffer;
          end loop;
       end if;

       m_send_payload := m_send_payload_temp;
       dbms_lob.freetemporary(lob_loc => m_send_payload_temp);
    end if;
    return m_send_payload;
  end;

  -- Преобразование суммы в текст (с валютой)
  function str_amount_curr (p_amount     number,
                            p_curr_code  varchar2 default 'UAH',
                            p_is_decimal char default 'F')
    return varchar2
  is
    type WordType is table of varchar2(30) index by binary_integer;
    dig       WordType;
    dig_a     WordType;
    ten       WordType;
    hun       WordType;
    tis       WordType;
    mln       WordType;
    mlrd      WordType;
    i         integer := 0;
    CurrValue integer;
    OriginVal integer;
    Fraction  integer;
    l         integer;
    S         integer;
    DIGIT     varchar2(255);
    RADIX     varchar2(255);
    CResult   varchar2(20);
    p_result    varchar2(255);
  begin
    CurrValue := trunc(p_amount);
    OriginVal := CurrValue;
    Fraction  := trunc((p_amount - CurrValue) * 100);

    -- тысячи
    tis(0) := 'тисяч ';
    tis(1) := 'тисяча ';
    tis(2) := 'тисячi ';
    tis(3) := 'тисячi ';
    tis(4) := 'тисячi ';
    tis(5) := 'тисяч ';
    tis(6) := 'тисяч ';
    tis(7) := 'тисяч ';
    tis(8) := 'тисяч ';
    tis(9) := 'тисяч ';
    tis(10) := 'тисяч ';
    tis(11) := 'тисяч ';
    tis(12) := 'тисяч ';
    tis(13) := 'тисяч ';
    tis(14) := 'тисяч ';
    tis(15) := 'тисяч ';
    tis(16) := 'тисяч ';
    tis(17) := 'тисяч ';
    tis(18) := 'тисяч ';
    tis(19) := 'тисяч ';

    -- мiльйон
    mln(0) := 'мiльйонiв ';
    mln(1) := 'мiльйон ';
    mln(2) := 'мiльйона ';
    mln(3) := 'мiльйона ';
    mln(4) := 'мiльйона ';
    mln(5) := 'мiльйонiв ';
    mln(6) := 'мiльйонiв ';
    mln(7) := 'мiльйонiв ';
    mln(8) := 'мiльйонiв ';
    mln(9) := 'мiльйонiв ';
    mln(10) := 'мiльйонiв ';
    mln(11) := 'мiльйонiв ';
    mln(12) := 'мiльйонiв ';
    mln(13) := 'мiльйонiв ';
    mln(14) := 'мiльйонiв ';
    mln(15) := 'мiльйонiв ';
    mln(16) := 'мiльйонiв ';
    mln(17) := 'мiльйонiв ';
    mln(18) := 'мiльйонiв ';
    mln(19) := 'мiльйонiв ';

    -- мiльярдiв
    mlrd(0) := ' ';
    mlrd(1) := 'мiльярд ';
    mlrd(2) := 'мiльярда ';
    mlrd(3) := 'мiльярда ';
    mlrd(4) := 'мiльярда ';
    mlrd(5) := 'мiльярдiв ';
    mlrd(6) := 'мiльярдiв ';
    mlrd(7) := 'мiльярдiв ';
    mlrd(8) := 'мiльярдiв ';
    mlrd(9) := 'мiльярдiв ';
    mlrd(10) := 'мiльярдiв ';
    mlrd(11) := 'мiльярдiв ';
    mlrd(12) := 'мiльярдiв ';
    mlrd(13) := 'мiльярдiв ';
    mlrd(14) := 'мiльярдiв ';
    mlrd(15) := 'мiльярдiв ';
    mlrd(16) := 'мiльярдiв ';
    mlrd(17) := 'мiльярдiв ';
    mlrd(18) := 'мiльярдiв ';
    mlrd(19) := 'мiльярдiв ';

    Dig(0) := '';
    dig(1) := 'один ';
    dig(2) := 'два ';
    dig(3) := 'три ';
    dig(4) := 'чотири ';
    dig(5) := 'п''ять ';
    dig(6) := 'шiсть ';
    dig(7) := 'сiм ';
    dig(8) := 'вiсiм ';
    dig(9) := 'дев''ять ';
    dig(10) := 'десять ';
    dig(11) := 'одинадцять ';
    dig(12) := 'дванадцять ';
    dig(13) := 'тринадцять ';
    dig(14) := 'чотирнадцять ';
    dig(15) := 'п''ятнадцять ';
    dig(16) := 'шiстнадцять ';
    dig(17) := 'сiмнадцять ';
    dig(18) := 'вiсiмнадцять ';
    dig(19) := 'дев''ятнадцять ';

    Dig_a(0) := '';
    dig_a(1) := 'один ';
    dig_a(2) := 'два ';
    dig_a(3) := 'три ';
    dig_a(4) := 'чотири ';
    dig_a(5) := 'п''ять ';
    dig_a(6) := 'шiсть ';
    dig_a(7) := 'сiм ';
    dig_a(8) := 'вiсiм ';
    dig_a(9) := 'дев''ять ';
    dig_a(10) := 'десять ';
    dig_a(11) := 'одинадцять ';
    dig_a(12) := 'дванадцять ';
    dig_a(13) := 'тринадцять ';
    dig_a(14) := 'чотирнадцять ';
    dig_a(15) := 'п''ятнадцять ';
    dig_a(16) := 'шiстнадцять ';
    dig_a(17) := 'сiмнадцять ';
    dig_a(18) := 'вiсiмнадцять ';
    dig_a(19) := 'дев''ятнадцять ';

    ten(0) := '';
    ten(1) := '';
    ten(2) := 'двадцять ';
    ten(3) := 'тридцять ';
    ten(4) := 'сорок ';
    ten(5) := 'п''ятдесят ';
    ten(6) := 'шiстдесят ';
    ten(7) := 'сiмдесят ';
    ten(8) := 'вiсiмдесят ';
    ten(9) := 'дев''яносто ';

    Hun(0) := '';
    Hun(1) := 'сто ';
    Hun(2) := 'двiстi ';
    Hun(3) := 'триста ';
    Hun(4) := 'чотириста ';
    Hun(5) := 'п''ятсот ';
    Hun(6) := 'шiстсот ';
    Hun(7) := 'сiмсот ';
    Hun(8) := 'вiсiмсот ';
    Hun(9) := 'дев''ятсот ';

    if Currvalue = 0
    then
      p_result := 'Нуль ';
    else
      while CurrValue > 0
      loop
        if (CurrValue mod 1000) <> 0
        then
          S := CurrValue mod 100;
          if S < 20
          then
            if i <= 1
            then
              if p_curr_code = 'UAH'
              then
                DIGIT := dig_a(s);
              else
                DIGIT := dig(s);
              end if;
            else
              DIGIT := dig(s);
            end if;

            if i = 0 then
              RADIX := '';
            elsif i = 1 then
              RADIX := tis(s);
            elsif i = 2 then
              RADIX := mln(s);
            elsif i = 3 then
              RADIX := mlrd(s);
            end if;

            p_result := DIGIT || RADIX || p_result;
          else

            if i <= 1 then
              DIGIT := dig_a(mod(s, 10));
            else
              DIGIT := dig(mod(s, 10));
            end if;

            if i = 0 then
              RADIX := '';
            elsif i = 1 then
              RADIX := tis(mod(s, 10));
            elsif i = 2 then
              begin
                if mod(s, 10) = 0 then
                  RADIX := mln(5);
                else
                  RADIX := mln(mod(s, 10));
                end if;
              end;
            elsif i = 3 then
              begin
                if mod(s, 10) = 0 then
                  RADIX := mlrd(5);
                else
                  RADIX := mlrd(mod(s, 10));
                end if;
              end;
            end if;

            p_result := Ten(trunc(S / 10)) || DIGIT || RADIX || p_result;

          end if;
          CurrValue := trunc(CurrValue / 100);
          S         := CurrValue mod 10;
          p_result    := Hun(S) || p_result;
          CurrValue := trunc(CurrValue / 10);
          i         := i + 1;
        else
          CurrValue := trunc(CurrValue / 1000);
          i         := i + 1;
        end if;
      end loop;
    end if;

    if p_is_decimal = 'T' then
      p_result := p_result || ' цiлих ' || to_char(fraction, '00') || ' сотих';
    else
      if (upper(p_curr_code) = 'UAH') or (trim(p_curr_code) is null) then
        CResult := to_char(OriginVal);
        l       := length(CResult);
        if ((l > 1) and (to_number(substr(CResult, l - 1, 2)) > 10) and
           (to_number(substr(CResult, l - 1, 2)) < 20)) then
          p_result := p_result || ' гривень';
        elsif to_number(substr(CResult, l, 1)) = 0 then
          p_result := p_result || ' гривень';
        elsif to_number(substr(CResult, l, 1)) = 1 then
          p_result := p_result || ' гривня';
        elsif (to_number(substr(CResult, l, 1)) = 2) or
              (to_number(substr(CResult, l, 1)) = 3) or
              (to_number(substr(CResult, l, 1)) = 4) then
          p_result := p_result || ' гривні';
        else
          p_result := p_result || ' гривень';
        end if;
  ------------------------------------------------------------------
        if substr(fraction,1,2) in (01,21,31,41,51,61,71,81,91) then
          p_result := p_result || to_char(fraction, '00') || ' копійка';
        elsif substr(fraction,1,2) in (02,03,04,22,23,24,32,33,34,
                                       42,43,44,52,53,54,62,63,64,
                                       72,73,74,82,83,84,92,93,94) then
          p_result := p_result || to_char(fraction, '00') || ' копійки';
        else
          p_result := p_result || to_char(fraction, '00') || ' копійок';
        end if;
  ------------------------------------------------------------------
      elsif (upper(p_curr_code) = 'USD') then
        CResult := to_char(OriginVal);
        l       := length(CResult);
        if ((l > 1) and (to_number(substr(CResult, l - 1, 2)) > 10) and
           (to_number(substr(CResult, l - 1, 2)) < 20)) then
          p_result := p_result || ' доларiв США';
        elsif to_number(substr(CResult, l, 1)) = 0 then
          p_result := p_result || ' доларiв США';
        elsif to_number(substr(CResult, l, 1)) = 1 then
          p_result := p_result || ' долар США';
        elsif (to_number(substr(CResult, l, 1)) = 2) or
              (to_number(substr(CResult, l, 1)) = 3) or
              (to_number(substr(CResult, l, 1)) = 4) then
          p_result := p_result || ' долари США';
        else
          p_result := p_result || ' доларiв США';
        end if;
  ------------------------------------------------------------------
        if substr(fraction,1,2) in (01,21,31,41,51,61,71,81,91) then
          p_result := p_result || to_char(fraction, '00') || ' цент';
        elsif substr(fraction,1,2) in (02,03,04,22,23,24,32,33,34,
                                       42,43,44,52,53,54,62,63,64,
                                       72,73,74,82,83,84,92,93,94) then
          p_result := p_result || to_char(fraction, '00') || ' центи';
        else
          p_result := p_result || to_char(fraction, '00') || ' центiв';
        end if;
  ------------------------------------------------------------------

        elsif (upper(p_curr_code) = 'EUR') then
          p_result := p_result || ' євро ' ;
  ------------------------------------------------------------------
        if substr(fraction,1,2) in (01,21,31,41,51,61,71,81,91) then
          p_result := p_result || to_char(fraction, '00') || ' євроцент';
        elsif substr(fraction,1,2) in (02,03,04,22,23,24,32,33,34,
                                       42,43,44,52,53,54,62,63,64,
                                       72,73,74,82,83,84,92,93,94) then
          p_result := p_result || to_char(fraction, '00') || ' євроценти';
        else
          p_result := p_result || to_char(fraction, '00') || ' євроцентiв';
        end if;
  ------------------------------------------------------------------

        elsif (upper(p_curr_code) = 'GBP') then
          CResult := to_char(OriginVal);
          l       := length(CResult);
        if ((l > 1) and (to_number(substr(CResult, l - 1, 2)) > 10) and
           (to_number(substr(CResult, l - 1, 2)) < 20)) then
          p_result := p_result || ' англійських Фунтів стерлінгів';
        elsif to_number(substr(CResult, l, 1)) = 0 then
          p_result := p_result || ' англійських Фунтів стерлінгів';
        elsif to_number(substr(CResult, l, 1)) = 1 then
          p_result := p_result || ' англійських Фунт стерлінгів';
        elsif (to_number(substr(CResult, l, 1)) = 2) or
              (to_number(substr(CResult, l, 1)) = 3) or
              (to_number(substr(CResult, l, 1)) = 4) then
          p_result := p_result || ' англійських Фунти стерлінгів';
        else
          p_result := p_result || ' англійських Фунтів стерлінгів';
        end if;
  ------------------------------------------------------------------
        if substr(fraction,1,2) in (01,21,31,41,51,61,71,81,91) then
          p_result := p_result || to_char(fraction, '00') || ' пенс';
        elsif substr(fraction,1,2) in (02,03,04,22,23,24,32,33,34,
                                       42,43,44,52,53,54,62,63,64,
                                       72,73,74,82,83,84,92,93,94) then
          p_result := p_result || to_char(fraction, '00') || ' пенси';
        else
          p_result := p_result || to_char(fraction, '00') || ' пенсiв';
        end if;
  ------------------------------------------------------------------

        elsif (upper(p_curr_code) = 'CHF') then
          CResult := to_char(OriginVal);
          l       := length(CResult);
        if ((l > 1) and (to_number(substr(CResult, l - 1, 2)) > 10) and
           (to_number(substr(CResult, l - 1, 2)) < 20)) then
          p_result := p_result || ' швейцарських франків';
        elsif to_number(substr(CResult, l, 1)) = 0 then
          p_result := p_result || ' швейцарських франків';
        elsif to_number(substr(CResult, l, 1)) = 1 then
          p_result := p_result || ' швейцарський франк';
        elsif (to_number(substr(CResult, l, 1)) = 2) or
              (to_number(substr(CResult, l, 1)) = 3) or
              (to_number(substr(CResult, l, 1)) = 4) then
          p_result := p_result || ' швейцарських франки';
        else
          p_result := p_result || ' швейцарських франків';
        end if;
  ------------------------------------------------------------------
        if substr(fraction,1,2) in (01,21,31,41,51,61,71,81,91) then
          p_result := p_result || to_char(fraction, '00') || ' сантим';
        elsif substr(fraction,1,2) in (02,03,04,22,23,24,32,33,34,
                                       42,43,44,52,53,54,62,63,64,
                                       72,73,74,82,83,84,92,93,94) then
          p_result := p_result || to_char(fraction, '00') || ' сантими';
        else
          p_result := p_result || to_char(fraction, '00') || ' сантимiв';
        end if;
  ------------------------------------------------------------------

        elsif (upper(p_curr_code) = 'RUR') then
          CResult := to_char(OriginVal);
          l       := length(CResult);
        if ((l > 1) and (to_number(substr(CResult, l - 1, 2)) > 10) and
           (to_number(substr(CResult, l - 1, 2)) < 20)) then
          p_result := p_result || 'російських рублів';
        elsif to_number(substr(CResult, l, 1)) = 0 then
          p_result := p_result || 'російських рублів';
        elsif to_number(substr(CResult, l, 1)) = 1 then
          p_result := p_result || 'російський рубель';
        elsif (to_number(substr(CResult, l, 1)) = 2) or
              (to_number(substr(CResult, l, 1)) = 3) or
              (to_number(substr(CResult, l, 1)) = 4) then
          p_result := p_result || 'російських рубля';
        else
          p_result := p_result || 'російських рублів';
        end if;
  ------------------------------------------------------------------
        if substr(fraction,1,2) in (01,21,31,41,51,61,71,81,91) then
          p_result := p_result || to_char(fraction, '00') || ' копійка';
        elsif substr(fraction,1,2) in (02,03,04,22,23,24,32,33,34,
                                       42,43,44,52,53,54,62,63,64,
                                       72,73,74,82,83,84,92,93,94) then
          p_result := p_result || to_char(fraction, '00') || ' копійки';
        else
          p_result := p_result || to_char(fraction, '00') || ' копійок';
        end if;
  ------------------------------------------------------------------

        elsif (upper(p_curr_code) = 'RUB') then
          CResult := to_char(OriginVal);
          l       := length(CResult);
        if ((l > 1) and (to_number(substr(CResult, l - 1, 2)) > 10) and
           (to_number(substr(CResult, l - 1, 2)) < 20)) then
          p_result := p_result || 'російських рублів';
        elsif to_number(substr(CResult, l, 1)) = 0 then
          p_result := p_result || 'російських рублів';
        elsif to_number(substr(CResult, l, 1)) = 1 then
          p_result := p_result || 'російський рубель';
        elsif (to_number(substr(CResult, l, 1)) = 2) or
              (to_number(substr(CResult, l, 1)) = 3) or
              (to_number(substr(CResult, l, 1)) = 4) then
          p_result := p_result || 'російських рубля';
        else
          p_result := p_result || 'російських рублів';
        end if;
  ------------------------------------------------------------------
        if substr(fraction,1,2) in (01,21,31,41,51,61,71,81,91) then
          p_result := p_result || to_char(fraction, '00') || ' копійка';
        elsif substr(fraction,1,2) in (02,03,04,22,23,24,32,33,34,
                                       42,43,44,52,53,54,62,63,64,
                                       72,73,74,82,83,84,92,93,94) then
          p_result := p_result || to_char(fraction, '00') || ' копійки';
        else
          p_result := p_result || to_char(fraction, '00') || ' копійок';
        end if;
  ------------------------------------------------------------------

        else
          p_result := p_result || ' ' || to_char(fraction, '00') || ' ' ||
                  p_curr_code;
        end if;
    end if;

    p_result := upper(substr(p_result, 1, 1)) || substr(p_result, 2, 254);
    p_result := replace(p_result, '  ', ' ');

    return(trim(substr(p_result, 1, 255)));

  exception when others
  then
      return(p_result);
  end;

  -- Преобразование суммы в текст
  function str_amount (p_amount number, p_is_default char := 'T') return varchar2
  is
    type WordType is table of varchar2(30) index by binary_integer;
    dig       WordType;
    dig_a     WordType;
    ten       WordType;
    hun       WordType;
    tis       WordType;
    mln       WordType;
    mlrd      WordType;
    i         integer := 0;
    CurrValue integer;
    S         integer;
    p_result  varchar2(255);
    DIGIT     varchar2(255);
    RADIX     varchar2(255);
  begin
    CurrValue := trunc(p_amount);
    -- тысячи
    tis(0) := 'тисяч ';
    tis(1) := 'тисяча ';
    tis(2) := 'тисячi ';
    tis(3) := 'тисячi ';
    tis(4) := 'тисячi ';
    tis(5) := 'тисяч ';
    tis(6) := 'тисяч ';
    tis(7) := 'тисяч ';
    tis(8) := 'тисяч ';
    tis(9) := 'тисяч ';
    tis(10) := 'тисяч ';
    tis(11) := 'тисяч ';
    tis(12) := 'тисяч ';
    tis(13) := 'тисяч ';
    tis(14) := 'тисяч ';
    tis(15) := 'тисяч ';
    tis(16) := 'тисяч ';
    tis(17) := 'тисяч ';
    tis(18) := 'тисяч ';
    tis(19) := 'тисяч ';
    -- мiльйон
    mln(0) := 'мiльйонiв ';
    mln(1) := 'мiльйон ';
    mln(2) := 'мiльйона ';
    mln(3) := 'мiльйона ';
    mln(4) := 'мiльйона ';
    mln(5) := 'мiльйонiв ';
    mln(6) := 'мiльйонiв ';
    mln(7) := 'мiльйонiв ';
    mln(8) := 'мiльйонiв ';
    mln(9) := 'мiльйонiв ';
    mln(10) := 'мiльйонiв ';
    mln(11) := 'мiльйонiв ';
    mln(12) := 'мiльйонiв ';
    mln(13) := 'мiльйонiв ';
    mln(14) := 'мiльйонiв ';
    mln(15) := 'мiльйонiв ';
    mln(16) := 'мiльйонiв ';
    mln(17) := 'мiльйонiв ';
    mln(18) := 'мiльйонiв ';
    mln(19) := 'мiльйонiв ';
    -- мiльярдiв
    mlrd(0) := ' ';
    mlrd(1) := 'мiльярд ';
    mlrd(2) := 'мiльярда ';
    mlrd(3) := 'мiльярда ';
    mlrd(4) := 'мiльярда ';
    mlrd(5) := 'мiльярдiв ';
    mlrd(6) := 'мiльярдiв ';
    mlrd(7) := 'мiльярдiв ';
    mlrd(8) := 'мiльярдiв ';
    mlrd(9) := 'мiльярдiв ';
    mlrd(10) := 'мiльярдiв ';
    mlrd(11) := 'мiльярдiв ';
    mlrd(12) := 'мiльярдiв ';
    mlrd(13) := 'мiльярдiв ';
    mlrd(14) := 'мiльярдiв ';
    mlrd(15) := 'мiльярдiв ';
    mlrd(16) := 'мiльярдiв ';
    mlrd(17) := 'мiльярдiв ';
    mlrd(18) := 'мiльярдiв ';
    mlrd(19) := 'мiльярдiв ';

    Dig(0) := '';
    dig(1) := 'один ';
    dig(2) := 'два ';
    dig(3) := 'три ';
    dig(4) := 'чотири ';
    dig(5) := 'п''ять ';
    dig(6) := 'шiсть ';
    dig(7) := 'сiм ';
    dig(8) := 'вiсiм ';
    dig(9) := 'дев''ять ';
    dig(10) := 'десять ';
    dig(11) := 'одинадцять ';
    dig(12) := 'дванадцять ';
    dig(13) := 'тринадцять ';
    dig(14) := 'чотирнадцять ';
    dig(15) := 'п''ятнадцять ';
    dig(16) := 'шiстнадцять ';
    dig(17) := 'сiмнадцять ';
    dig(18) := 'вiсiмнадцять ';
    dig(19) := 'дев''ятнадцять ';

    Dig_a(0) := '';
    dig_a(1) := 'одна ';
    dig_a(2) := 'двi ';
    dig_a(3) := 'три ';
    dig_a(4) := 'чотири ';
    dig_a(5) := 'п''ять ';
    dig_a(6) := 'шiсть ';
    dig_a(7) := 'сiм ';
    dig_a(8) := 'вiсiм ';
    dig_a(9) := 'дев''ять ';
    dig_a(10) := 'десять ';
    dig_a(11) := 'одинадцять ';
    dig_a(12) := 'дванадцять ';
    dig_a(13) := 'тринадцять ';
    dig_a(14) := 'чотирнадцять ';
    dig_a(15) := 'п''ятнадцять ';
    dig_a(16) := 'шiстнадцять ';
    dig_a(17) := 'сiмнадцять ';
    dig_a(18) := 'вiсiмнадцять ';
    dig_a(19) := 'дев''ятнадцять ';

    ten(0) := '';
    ten(1) := '';
    ten(2) := 'двадцять ';
    ten(3) := 'тридцять ';
    ten(4) := 'сорок ';
    ten(5) := 'п''ятдесят ';
    ten(6) := 'шiстдесят ';
    ten(7) := 'сiмдесят ';
    ten(8) := 'вiсiмдесят ';
    ten(9) := 'дев''яносто ';

    Hun(0) := '';
    Hun(1) := 'сто ';
    Hun(2) := 'двiстi ';
    Hun(3) := 'триста ';
    Hun(4) := 'чотириста ';
    Hun(5) := 'п''ятсот ';
    Hun(6) := 'шiстсот ';
    Hun(7) := 'сiмсот ';
    Hun(8) := 'вiсiмсот ';
    Hun(9) := 'дев''ятсот ';

    if Currvalue = 0
    then
      p_result := 'Нуль ';
    else
      while CurrValue > 0
      loop
        if (CurrValue mod 1000) <> 0
        then
          S := CurrValue mod 100;
          if S < 20 then

            if i <= 1 then
              if p_is_default = 'T' then
                DIGIT := dig_a(s);
              else
                if i = 1 then
                  DIGIT := dig_a(s);
                else
                  DIGIT := dig(s);
                end if;
              end if;
            else
              DIGIT := dig(s);
            end if;

            if i = 0 then
              RADIX := '';
            elsif i = 1 then
              RADIX := tis(s);
            elsif i = 2 then
              RADIX := mln(s);
            elsif i = 3 then
              RADIX := mlrd(s);
            end if;

            p_result := DIGIT||RADIX|| p_result;
          else

            if i <= 1 then
              if p_is_default = 'T' then
                DIGIT := dig_a(mod(s, 10));
              else
                DIGIT := dig(mod(s, 10));
              end if;
            else
              DIGIT := dig(mod(s, 10));
            end if;

            if i = 0 then
              RADIX := '';
            elsif i = 1 then
              RADIX := tis(mod(s, 10));
            elsif i = 2 then
              begin
              if mod(s, 10) = 0 then
                 RADIX := mln(5);
              else
                 RADIX := mln(mod(s, 10));
              end if;
              end;
            elsif i = 3 then
              begin
              if mod(s, 10) = 0 then
                 RADIX := mlrd(5);
              else
                 RADIX := mlrd(mod(s, 10));
              end if;
              end;
            end if;

            p_result := Ten(trunc(S/10))||DIGIT||RADIX||p_result;

          end if;
          CurrValue := trunc(CurrValue/100);
          S := CurrValue mod 10;
          p_result := Hun(S) ||p_result;
          CurrValue := trunc(CurrValue/10);
          i := i + 1;
        else
          CurrValue := trunc(CurrValue/1000);
          i := i + 1;
        end if;
      end loop;
    end if;

    p_result := upper(substr(p_result, 1, 1))||substr(p_result, 2, 254);
    return(trim(substr(p_result, 1, 255)));

  exception when others
  then
    return(p_result);
  end;

  -- Преобразование суммы в текстовый формат числа
  function str_amount_format (p_number number, p_count_comma pls_integer default 2) return varchar2
  is
    p_n varchar2(255);
    pos pls_integer;
    p_num number;
  begin
    if p_number is null then return p_number; end if;
    p_num := p_number;
    if p_num > 999999999999 then p_num := 999999999999; end if;

    if p_count_comma = 0 then p_n := to_char(p_num,'999G999G999G990'); end if;
    if p_count_comma = 1 then p_n := to_char(p_num,'999G999G999G990D0'); end if;
    if p_count_comma = 2 then p_n := to_char(p_num,'999G999G999G990D00'); end if;
    if p_count_comma = 3 then p_n := to_char(p_num,'999G999G999G990D000'); end if;
    if p_count_comma = 4 then p_n := to_char(p_num,'999G999G999G990D0000'); end if;
    if p_count_comma = 5 then p_n := to_char(p_num,'999G999G999G990D00000'); end if;
    if p_count_comma > 5 or p_count_comma is null
    then
       raise_application_error(-20000, 'Количество знаков после запятой не может быль больше 5 или NULL !!!', true);
    end if;

    p_n := replace(p_n,'.',chr(44));
    p_n := replace(p_n,chr(44),' ');
    p_n := trim(p_n);

    -- восстанавливаем последнюю запятую
    pos := instr(p_n,' ',-1,1);
    if p_count_comma = 0 then p_n := p_n; end if;
    if p_count_comma <> 0 then p_n := substr(p_n,1,pos-1) || chr(44) || substr(p_n,pos+1,length(p_n)-pos); end if;

    return p_n;
  end;

  -- Преобразование процента с тест (0,5678999% (нуль цiлих i п'ять мiльйонiв шiстсот сiмдесят вiсiм тисяч дев'ятсот дев'яносто дев'ять десятимільйонних процента))
  function str_interest (p_amount number) return varchar2
  is
    p_result      varchar2(255);
    Fraction      number;
    FractionType  varchar2(255);
    FractionT     varchar2(255);
    FractionFM    varchar2(255);
    p_last_amount number;
  begin
    Fraction := p_amount - Trunc(p_amount);
    FractionT := substr(num_to_str(Fraction),3);
    FractionFM := 'FM999,999,999,990.00';
    if    length(FractionT) = 1 then
             FractionType := 'десятих';
             Fraction := Fraction * 10;
    elsif length(FractionT) = 2 then
             FractionType := 'сотих';
             Fraction := Fraction * 100;
    elsif length(FractionT) = 3 then
             FractionType := 'тисячних';
             Fraction := Fraction * 1000;
             FractionFM := 'FM999,999,999,990.000';
    elsif length(FractionT) = 4 then
             FractionType := 'десятитисячних';
             Fraction := Fraction * 10000;
             FractionFM := 'FM999,999,999,990.0000';
    elsif length(FractionT) = 5 then
             FractionType := 'стотисячних';
             Fraction := Fraction * 100000;
             FractionFM := 'FM999,999,999,990.00000';
    elsif length(FractionT) = 6 then
             FractionType := 'мільйонних';
             Fraction := Fraction * 1000000;
             FractionFM := 'FM999,999,999,990.000000';
    elsif length(FractionT) = 7 then
             FractionType := 'десятимільйонних';
             Fraction := Fraction * 10000000;
             FractionFM := 'FM999,999,999,990.0000000';
    elsif length(FractionT) = 8 then
             FractionType := 'стомільйонних';
             Fraction := Fraction * 100000000;
             FractionFM := 'FM999,999,999,990.00000000';
    elsif length(FractionT) > 8
      then
         return null;
    end if;

    if Fraction = 0
    then
      p_result := trim(to_char(p_amount, FractionFM))||'% ('||str_amount(p_amount, 'F');

      -- добавляем
      p_last_amount := to_number(substr(to_char(p_amount), -1, 1));
      if (p_last_amount in (0,5,6,7,8,9) or p_amount in (11,12,13,14,15,16,17,18,19)) then p_result := p_result||' процентiв)';
      elsif p_last_amount = 1 then p_result := p_result||' процент)';
      elsif p_last_amount in (2,3,4) then p_result := p_result||' процента)';
      else
         p_result := p_result||' процента)';
      end if;

    else
      p_result := trim(to_char(p_amount, FractionFM))||'% ('||str_amount(p_amount);

      if trunc(p_amount) = 1
      then
         p_result := p_result||' цiла i '||lower(str_amount(Fraction))||' '||FractionType;
      else
         p_result := p_result||' цiлих i '||lower(str_amount(Fraction))||' '||FractionType;
      end if;

      p_result := p_result||' процента)';
    end if;

    p_result := lower(p_result);

    -- замена
    if FractionType is not null and substr(num_to_str(p_amount),-1) = '1'
        and substr(num_to_str(p_amount),-2) != '11'
    then
        if    length(FractionT) = 1 then p_result := replace(p_result, 'десятих', 'десята');
        elsif length(FractionT) = 2 then p_result := replace(p_result, 'сотих', 'сота');
        elsif length(FractionT) = 3 then p_result := replace(p_result, 'тисячних', 'тисячна');
        elsif length(FractionT) = 4 then p_result := replace(p_result, 'десятитисячних', 'десятитисячна');
        elsif length(FractionT) = 5 then p_result := replace(p_result, 'стотисячних', 'стотисячна');
        elsif length(FractionT) = 6 then p_result := replace(p_result, 'мільйонних', 'мільйонна');
        elsif length(FractionT) = 7 then p_result := replace(p_result, 'десятимільйонних', 'десятимільйонна');
        elsif length(FractionT) = 8 then p_result := replace(p_result, 'стомільйонних', 'стомільйонна');
        end if;
    end if;

    return replace((trim(substr(p_result, 1, 255))), '.', ',');

  exception when others
  then
    return p_result;
  end;

  -- Преобразование теста с UTF8 в базовую кодировку Oracle (до 4000 символов)
  function get_charset_utf8(p_text varchar2) return varchar2
  is
  begin
    if p_text in ('null', 'nul') then return null; end if;
    -- В кодировку базы (максимум: 4000 или ошибка ORA-22835)
    return UTL_I18N.raw_to_char(UTL_I18N.STRING_TO_RAW(p_text, m_base_charset), 'UTF8');
  exception when others then
      return p_text;
  end;

  -- Преобразование теста с базовую кодировки Oracle в UTF8 (до 4000 символов)
  function to_charset_utf8(p_text varchar2) return varchar2
  is
  begin
    -- В кодировку базы (максимум: 4000 или ошибка ORA-22835)
    return UTL_I18N.raw_to_char(UTL_I18N.STRING_TO_RAW(p_text, 'UTF8'), m_base_charset);
  exception when others then
      return p_text;
  end;

   -- Экранирование символов для JSON с доп. конвертацией в UTF8
  function screening_json(p_str in varchar2, p_is_convert_utf8 varchar2 default 'F') return varchar2
  is
    p_result varchar2(32767);
  begin
    if p_is_convert_utf8 = 'T'
    then
       p_result := to_charset_utf8(p_str);
    else
       p_result := p_str;
    end if;

    -- для JSON экранируем служебные символы
    p_result := replace(p_result,'\','\\');
    p_result := replace(p_result,'"','\"');
    p_result := replace(p_result,'/','\/');
    return p_result;
  end;

  -- Преобразование теста с число
  function str_to_num (p_text in varchar2) return number
  is
    m_text varchar2(32000);
  begin
    m_text := replace(p_text,',','.');
    return(to_number(trim(m_text), '999999999999999999999999999999.99999999999999999999999999999'));
  exception when others
  then
     raise_application_error(-20000, 'Невозможно преобразовать в число ='||p_text, true);
  end;

  -- Преобразование теста в дату
  function str_to_date (p_text in varchar2, p_format in VARCHAR2 default 'dd.mm.yyyy') return date
  is
  begin
    return(to_date(trim(p_text), p_format));
  exception when others
  then
     raise_application_error(-20000, 'Невозможно преобразовать в дату ='||p_text, true);
  end;

  -- Преобразование числа в тест
  function num_to_str (p_amount number) return varchar2
  is
     m_result   varchar2(60);
     m_len      pls_integer;
  begin
     if p_amount is null then return ''; end if;

     m_result := trim(to_char(p_amount, '999999999999999999999999999999.99999999999999999999999999999'));
     m_len    := length(m_result);

     for i in 0..m_len
     loop
       if substr(m_result, m_len - i, 1) != '0'
       then
         exit;
       else
         m_result := substr(m_result, 1, m_len - (i + 1));
       end if;
     end loop;

     m_result := trim(m_result);
     m_len    := length(m_result);

     if substr(m_result, m_len, 1) in ('.', ',')
     then
       m_result := substr(m_result, 1, m_len - 1);
     end if;

     m_result := trim(m_result);

     if substr(m_result, 1, 1) in ('.', ',')
     then
       m_result := '0'||m_result;
     end if;

     return m_result;
  end;

  -- Преобразование теста из одной в другую кодировку
  -- 'UTF8','CL8MSWIN1251'
  function convert_str(p_text          varchar2,
                       p_char_set_to   varchar2, -- преобразовать в
                       p_char_set_from varchar2 default null) -- преобразования из
    return varchar2
  is
  begin
      if p_char_set_from is null
      then
         return convert(p_text, p_char_set_to);
      else
         return convert(p_text, p_char_set_to, p_char_set_from);
      end if;
  end;

  -- Преобразование теста в дату и время (формат YYYY-MM-DDThh24:mi:ssZ)
  function get_datetime(p_text varchar2) return date
  as
    m_date date;
  begin
     if p_text in ('null', 'nul') then return null; end if;

     if length(p_text) > 20
     then
         select max(cast(TO_TIMESTAMP(p_text, 'YYYY-MM-DD"T"hh24:mi:ss.FF9"Z"') AS DATE)) into m_date
         from dual;
     elsif length(p_text) = 20
     then
         select max(cast(TO_TIMESTAMP(p_text, 'YYYY-MM-DD"T"hh24:mi:ss"Z"') AS DATE)) into m_date
         from dual;
     elsif length(p_text) = 17
     then
         select max(cast(TO_TIMESTAMP(p_text, 'YYYY-MM-DD"T"hh24:mi"Z"') AS DATE)) into m_date
         from dual;
     end if;

     return m_date;
  exception
     when self_is_null then
        return to_date(null);
  end;

  -- Описание (дні)
  function str_days (p_value integer) return varchar2
  is
    result     varchar2(255);
    p_name_day varchar2(255);
    DayValue   integer;
    CResult    varchar2(20);
    l          integer;
  begin
    DayValue := Trunc(p_value);
    CResult := to_char(DayValue);
    l := length(CResult);

    if ((l>1) and (to_number(substr(CResult,l-1,2))>10) and (to_number(substr(CResult,l-1,2))<20))
     then
       p_name_day := ' днів ';
    elsif to_number(substr(CResult,l,1))=0
     then
       p_name_day := ' днів ';
    elsif to_number(substr(CResult,l,1))=1
     then
       p_name_day := ' день ';
    elsif (to_number(substr(CResult,l,1))=2) or (to_number(substr(CResult,l,1))=3) or (to_number(substr(CResult,l,1))=4)
     then
       p_name_day:= ' дні ';
    else
       p_name_day := ' днів ';
    end if;

    Result := p_name_day;

    return (trim(substr(Result, 1, 255)));
  exception when others
  then
    return(Result);
  end;

  -- Описание (місяці)
  function str_month (p_value integer) return varchar2
  is
    result       varchar2(255);
    p_name_month varchar2(255);
    MonthValue   integer;
    CResult      varchar2(20);
    l            integer;
  begin
    MonthValue := Trunc(p_value);
    CResult := to_char(MonthValue);
    l := length(CResult);

    if ((l>1) and (to_number(substr(CResult,l-1,2))>10) and (to_number(substr(CResult,l-1,2))<20))
     then
       p_name_month := ' місяців ';
    elsif to_number(substr(CResult,l,1))=0
     then
       p_name_month := ' місяців ';
    elsif to_number(substr(CResult,l,1))=1
     then
       p_name_month := ' місяць ';
    elsif (to_number(substr(CResult,l,1))=2) or (to_number(substr(CResult,l,1))=3) or (to_number(substr(CResult,l,1))=4)
     then
       p_name_month:= ' місяці ';
    else
       p_name_month := ' місяців ';
    end if;

    Result := p_name_month;

    return (trim(substr(Result, 1, 255)));
  exception when others 
  then 
    return(Result);
  end;

end;
/
