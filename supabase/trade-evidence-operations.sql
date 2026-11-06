-- Nexus Capital Group | upgrade das operações para cenário/janela/prints
-- Executar no Supabase SQL Editor APÓS supabase/diario.sql e supabase/trade-operations.sql
alter table public.trade_operations
 add column if not exists scenario text,
 add column if not exists trade_window smallint,
 add column if not exists is_aplus boolean not null default false,
 add column if not exists evidence_path text;

alter table public.trade_operations
 drop constraint if exists trade_operations_scenario_check;
alter table public.trade_operations
 add constraint trade_operations_scenario_check check (scenario is null or scenario in ('01','02','03'));
alter table public.trade_operations
 drop constraint if exists trade_operations_trade_window_check;
alter table public.trade_operations
 add constraint trade_operations_trade_window_check check (trade_window is null or trade_window between 1 and 3);
alter table public.trade_operations
 drop constraint if exists trade_operations_evidence_path_check;
alter table public.trade_operations
 add constraint trade_operations_evidence_path_check check (
 evidence_path is null or (length(evidence_path)<400 and evidence_path !~ '[[:cntrl:]]')
);

-- Somente o proprio trader pode vincular comprovante ao seu registro.
-- O INSERT continua protegido pela politica original por user_id.
drop policy if exists "trade_operations_owner_evidence_update" on public.trade_operations;
create policy "trade_operations_owner_evidence_update"
 on public.trade_operations for update to authenticated
 using (user_id=auth.uid())
 with check (user_id=auth.uid() and (evidence_path is null or evidence_path like auth.uid()::text || '/%'));

-- Evita permitir edicao de lucro, resultado, valor e autoria no navegador.
revoke update on public.trade_operations from authenticated;
grant update (evidence_path) on public.trade_operations to authenticated;
grant select, insert on public.trade_operations to authenticated;
-- O acesso a imagens usa o bucket privado trade-evidence, com RLS
-- ja criado em supabase/diario.sql.
-- O nome do objeto deve iniciar com UUID do usuario / ...
