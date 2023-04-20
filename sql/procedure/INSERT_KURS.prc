CREATE OR REPLACE NONEDITIONABLE PROCEDURE INSERT_KURS
(
  P_KURS_DATE IN VARCHAR2,
  P_CURRENCY_CODE IN VARCHAR2,
  P_RATE IN NUMBER
) AS
BEGIN
    -- добавить курсы
    INSERT INTO kurs (ID, KURS_DATE, CURRENCY_CODE, RATE, IS_PRIMARY)
	     SELECT KURS_SEQ.nextval,
                TO_DATE(P_KURS_DATE, 'YYYY-MM-DD'),
                P_CURRENCY_CODE,
                P_RATE,
                decode(P_CURRENCY_CODE, 'USD', true, false)
        WHERE NOT EXISTS (SELECT 1 FROM kurs c where c.kurs_date = TO_DATE(P_KURS_DATE, 'YYYY-MM-DD') and c.currency_code = P_CURRENCY_CODE);

END INSERT_KURS;
/
