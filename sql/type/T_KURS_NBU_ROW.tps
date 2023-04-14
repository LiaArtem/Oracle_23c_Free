CREATE OR REPLACE NONEDITIONABLE TYPE T_KURS_NBU_ROW is object
(
 r030         varchar2(3),
 txt          varchar2(255),
 rate         number,
 cc           varchar2(3),
 exchangedate date
);
/
