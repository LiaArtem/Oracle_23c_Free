CREATE OR REPLACE NONEDITIONABLE TYPE T_FAIR_VALUE_ROW is object
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
/
