CREATE OR REPLACE NONEDITIONABLE TYPE T_ISIN_SECUR_ROW is object
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
/
