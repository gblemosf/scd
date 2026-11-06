-- Nexus Capital Group | Operações importadas de planilha
-- Execute este arquivo no SQL Editor do projeto Supabase "trade".
-- Depende das tabelas public.trade_profiles e da função public.trade_is_admin()
-- previamente criadas em supabase/diario.sql.
create table if not exists public.trade_operations (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.trade_profiles(id) on delete cascade,
 trade_date date not null,
 trade_time text not null check (trade_time ~ '^[0-2][0-9]:[0-5][0-9]$'),
 asset text not null check (length(asset) between 1 and 40),
 market text not null check (market in ('Real','OTC')),
 strategy text not null check (length(strategy) between 1 and 80),
 outcome text not null check (outcome in ('WIN','LOSS','EMPATE')),
 stake numeric(14,2) not null check (stake > 0),
 payout numeric(6,2) not null check (payout >= 0 and payout <= 100),
 notes text not null default '' check (length(notes) <= 500),
 import_key text not null check (length(import_key)=64),
 created_at timestamptz not null default now(),
 unique (user_id, import_key)
);
create index if not exists trade_operations_user_date_idx on public.trade_operations (user_id,trade_date desc);
create index if not exists trade_operations_date_idx on public.trade_operations (trade_date desc);
alter table public.trade_operations enable row level security;

drop policy if exists "trade_operations_read" on public.trade_operations;
create policy "trade_operations_read"
on public.trade_operations for select to authenticated
using (user_id=auth.uid() or public.trade_is_admin());

drop policy if exists "trade_operations_insert" on public.trade_operations;
create policy "trade_operations_insert"
on public.trade_operations for insert to authenticated
with check (user_id=auth.uid());

-- Só administradores podem remover registros; traders não podem alterar a auditoria.
drop policy if exists "trade_operations_admin_delete" on public.trade_operations;
create policy "trade_operations_admin_delete"
on public.trade_operations for delete to authenticated
using (public.trade_is_admin());

-- IMPORTANTE: Não criar política de UPDATE para usuários comuns.
-- P/L sempre é calculado a partir de stake, payout e resultado.
-- Prints não comprovam de forma independente dados autodeclarados.
