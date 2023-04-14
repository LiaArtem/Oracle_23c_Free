CREATE OR REPLACE NONEDITIONABLE PROCEDURE HTTP_REQUEST (p_url                  in varchar2, -- url
                                                         p_url_method           in varchar2 default 'POST', -- url method (POST, GET)
                                                         p_url_http_version     in varchar2 default 'HTTP/1.1', -- url http version
                                                         p_url_https_host       in varchar2 default null, -- url https host
                                                         p_header_authorization in varchar2 default null,
                                                         p_header_content_type  in varchar2 default 'application/json', -- text/xml
                                                         p_header_body_charset  in varchar2 default 'UTF-8', -- WINDOWS-1251
                                                         p_wallet_file          in varchar2 default null,
                                                         p_wallet_file_pwd      in varchar2 default null,
                                                         p_proxy                in varchar2 default null, -- '10.2.1.250:8888'
                                                         p_proxy_username       in varchar2 default null,
                                                         p_proxy_password       in varchar2 default null,
                                                         p_transfer_timeout     in integer default 60,
                                                         p_request_body         in clob default null, -- тело запроса
                                                         p_response_body        out clob, -- ответ (тело)
                                                         p_response_status_code out integer, -- ответ (код состояния)
                                                         p_response_status_desc out varchar2 -- ответ (описание состояния)
                                                        )
is
  m_http_response            UTL_HTTP.resp;
  m_http_request             UTL_HTTP.req;
  m_buffer_offset            integer;
  m_buf                      varchar2(32767);
  m_buffer_size              integer := 32767;
  m_read_buffer_size         integer := m_buffer_size;
  m_response                 clob;
  m_buff_chunked             integer;
begin
    -- для HTTPS хранение сертификата
    if p_wallet_file is not null
    then
       utl_http.set_wallet('file:'||p_wallet_file, p_wallet_file_pwd);
    end if;
    -- прокси
    if p_proxy is not null
    then
       utl_http.set_proxy(proxy => p_proxy, no_proxy_domains => null);
    end if;

    -- формирование запроса
    utl_http.set_response_error_check(false); -- true проверка ошибок ответа, false не проверять
    utl_http.set_transfer_timeout(p_transfer_timeout); -- длительность транзакции
    m_http_request := utl_http.begin_request(url          => p_url,
                                             METHOD       => p_url_method,
                                             HTTP_VERSION => p_url_http_version,
                                             https_host   => p_url_https_host
                                             );

    -- Authorization включает в себя данные пользователя для проверки подлинности пользовательского агента с
    -- сервером обычно после того, как сервер ответил со статусом 401 Unauthorized и заголовком WWW-Authenticate (en-US).
    if p_header_authorization is not null
    then
      utl_http.set_header(m_http_request, 'Authorization', p_header_authorization);
    end if;
    if p_header_content_type is not null
    then
       utl_http.set_header(m_http_request, 'Content-Type', p_header_content_type);
    end if;
    if nvl(dbms_lob.getlength(p_request_body),0) > 0
    then
       utl_http.set_header(m_http_request, 'Content-Length', dbms_lob.getlength(p_request_body));
    end if;
    if p_header_body_charset is not null
    then
       utl_http.set_body_charset(m_http_request, p_header_body_charset);
    end if;

    -- прокси
    if p_proxy is not null and p_proxy_username is not null
    then
       utl_http.set_authentication(r        => m_http_request,
                                   username => p_proxy_username,
                                   password => p_proxy_password,
                                   for_proxy => true);
    end if;

    <<Repeated_Send>>

    -- отправка
    m_buff_chunked := nvl(ceil(dbms_lob.getlength(p_request_body) / m_buffer_size),0);
    if m_buff_chunked > 1
    then
       utl_http.set_header(m_http_request, 'Transfer-Encoding', 'chunked');
    end if;

    m_buffer_offset := 1;
    for i in 1..m_buff_chunked
    loop
      dbms_lob.read(p_request_body, m_read_buffer_size, m_buffer_offset, m_buf);
      m_buffer_offset := m_buffer_offset + m_read_buffer_size;
      utl_http.write_text(m_http_request, m_buf);
    end loop;

    -- чтение ответа
    m_http_response := utl_http.get_response(m_http_request);
    if m_http_response.status_code = 100 -- Ожидание
    then
      dbms_lock.sleep(10);
      goto Repeated_Send;
    end if;

    dbms_lob.createtemporary(m_response, true);
    begin
      loop
         utl_http.read_text(m_http_response, m_buf);
         dbms_lob.writeappend(m_response, length(m_buf), m_buf);
      end loop;
    exception when utl_http.end_of_body then
        utl_http.end_response(m_http_response);
              when utl_http.too_many_requests then
        utl_http.end_response(m_http_response);
    end;

    -- пишем ответ
    p_response_body := m_response; -- out

    dbms_lob.freetemporary(m_response);

    -- дозакрываем соединения
    if m_http_request.private_hndl is not null
    then
       utl_http.end_request(m_http_request);
    end if;

    if m_http_response.private_hndl is not null
    then
       utl_http.end_response(m_http_response);
    end if;

    p_response_status_code := m_http_response.status_code; -- out
    p_response_status_desc := m_http_response.reason_phrase; -- out

  exception when others
  then
      if m_http_request.private_hndl is not null
      then
         utl_http.end_request (m_http_request);
      end if;

      if m_http_response.private_hndl is not null
      then
         utl_http.end_response (m_http_response);
      end if;

      p_response_status_code := -100; -- out
      p_response_status_desc := substr(dbms_utility.format_error_stack||dbms_utility.format_error_backtrace, 1, 7000); -- out
end;
/
