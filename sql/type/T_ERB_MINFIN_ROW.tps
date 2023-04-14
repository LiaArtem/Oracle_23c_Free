CREATE OR REPLACE NONEDITIONABLE TYPE T_ERB_MINFIN_ROW is object
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
/
