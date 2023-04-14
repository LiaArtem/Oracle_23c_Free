-- Чтобы работала отладка в SQL Developer
    BEGIN
     DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE
     (
     host => '127.0.0.1',
     lower_port => null,
     upper_port => null,
     ace => xs$ace_type(privilege_list => xs$name_list('jdwp'),
     principal_name => 'TEST_USER',
     principal_type => xs_acl.ptype_db)
     );
    END;

