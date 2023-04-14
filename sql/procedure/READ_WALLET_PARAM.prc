CREATE OR REPLACE NONEDITIONABLE PROCEDURE READ_WALLET_PARAM (p_wallet_file out varchar2, p_wallet_file_pwd out varchar2)
is
begin
  p_wallet_file := '/opt/wallet';
  p_wallet_file_pwd := '34534kjhsdffkjsdfgalfgb###';
end;
/
