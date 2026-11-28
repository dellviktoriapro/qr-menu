-- One minute scheduler; reminder becomes due after exactly 180 seconds.
-- The next scan sends it only while that submission remains unaccepted.
create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron;
select cron.schedule('rp-order-push','* * * * *','select rp_private.push_tick()');
