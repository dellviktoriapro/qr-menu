-- Test paper must work with all real-order printing switches OFF.
begin;
do $patch$
declare ddl text;old text;
begin
 ddl:=pg_get_functiondef('public.rp_print_test(uuid,text,uuid)'::regprocedure);
 old:='where cafe_id=c and purpose=p and enabled';
 if position(old in ddl)=0 then raise exception 'PRINT_TEST_CHANGED';end if;
 execute replace(ddl,old,'where cafe_id=c and purpose=p and rp_private.lan_host(host)');
 ddl:=pg_get_functiondef('public.rp_print_bridge_poll(text)'::regprocedure);
 old:='p.purpose=j.purpose and p.enabled';
 if position(old in ddl)=0 then raise exception 'PRINT_POLL_CHANGED';end if;
 execute replace(ddl,old,'p.purpose=j.purpose and (p.enabled or j.is_test)');
end $patch$;
commit;
