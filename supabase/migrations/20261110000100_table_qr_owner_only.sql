-- Narrow, idempotent patch: keep the installed guest workflow intact.
do $owner_qr$
declare ddl text;
begin
  ddl := pg_get_functiondef('rp_private.guest_staff(uuid,uuid,text,jsonb)'::regprocedure);
  if position('if a=''table_link'' and m.role=''owner'' then' in ddl) > 0 then
    return;
  end if;
  if position('if a=''table_link'' and m.role in (''owner'',''manager'') then' in ddl) = 0 then
    raise exception 'Unexpected table QR authorization rule; no changes applied';
  end if;
  ddl := replace(ddl,
    'if a=''table_link'' and m.role in (''owner'',''manager'') then',
    'if a=''table_link'' and m.role=''owner'' then');
  execute ddl;
end
$owner_qr$;
