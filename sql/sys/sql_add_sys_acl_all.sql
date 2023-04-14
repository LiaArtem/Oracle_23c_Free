BEGIN
DBMS_NETWORK_ACL_ADMIN.CREATE_ACL (
acl => '/sys/acls/utl_http.xml',
description => 'Allow http',
principal => 'PUBLIC',
is_grant => TRUE,
privilege => 'connect',
start_date => SYSTIMESTAMP,
end_date => NULL);
COMMIT;
END;
/

BEGIN
DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(
acl => '/sys/acls/utl_http.xml',
principal => 'PUBLIC',
is_grant => true,
privilege => 'connect');
COMMIT;
END;
/


BEGIN
DBMS_NETWORK_ACL_ADMIN.ADD_PRIVILEGE(
acl => '/sys/acls/utl_http.xml',
principal => 'PUBLIC',
is_grant => true,
privilege => 'resolve');
COMMIT;
END;
/

BEGIN
DBMS_NETWORK_ACL_ADMIN.ASSIGN_ACL (
acl => '/sys/acls/utl_http.xml',
host => '*');
COMMIT;
END;
/