-- Genesis Trade / Diário de Traders
-- Executar no SQL Editor do Supabase. NÃO colocar service_role no frontend.
create extension if not exists pgcrypto;

create table if not exists public.trade_profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null check (length(display_name) between 2 and 90),
 role text not null default 'trader' check (role in ('trader','admin')),
 created_at timestamptz not null default now()
);
create table if not exists public.trade_reports (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.trade_profiles(id),
 trader_name text not null check (length(trader_name) between 1 and 90),
 trade_day date not null,
 market text not null check (market in ('Real','OTC','Misto')),
 score text not null check (score in ('1x0','2x0','3x0','4x0','0x1','1x1','2x1','3x1','Outro')),
 trades int not null check (trades between 0 and 300),
 pnl numeric(14,2) not null,
 compliance text not null check (compliance in ('sim','nao','na')),
 notes text not null default '' check (length(notes) <= 1500),
 image_paths text[] not null check (cardinality(image_paths) between 1 and 4),
 review_status text not null default 'pendente' check (review_status in ('pendente','aprovado')),
 created_at timestamptz not null default now()
);
create index if not exists trade_reports_by_user_day on public.trade_reports (user_id,trade_day desc);
create index if not exists trade_reports_by_day on public.trade_reports (trade_day desc);

create or replace function public.trade_is_admin()
returns boolean language sql security definer stable
set search_path = public, pg_temp
as $$select exists(select 1 from public.trade_profiles where id=auth.uid() and role='admin')$$;
revoke all on function public.trade_is_admin() from public;
grant execute on function public.trade_is_admin() to authenticated;

alter table public.trade_profiles enable row level security;
alter table public.trade_reports enable row level security;

drop policy if exists "profile_self_or_admin_read" on public.trade_profiles;
create policy "profile_self_or_admin_read" on public.trade_profiles
 for select to authenticated using (id=auth.uid() or public.trade_is_admin());

drop policy if exists "profile_admin_write" on public.trade_profiles;
create policy "profile_admin_write" on public.trade_profiles
 for all to authenticated using (public.trade_is_admin()) with check (public.trade_is_admin());

drop policy if exists "reports_read_owner_or_admin" on public.trade_reports;
create policy "reports_read_owner_or_admin" on public.trade_reports
 for select to authenticated using (user_id=auth.uid() or public.trade_is_admin());

drop policy if exists "reports_insert_owner" on public.trade_reports;
create policy "reports_insert_owner" on public.trade_reports
 for insert to authenticated with check (
 user_id=auth.uid() and review_status='pendente'
 and trader_name=(select display_name from public.trade_profiles where id=auth.uid())
 and (select bool_and(split_part(p, '/', 1)=auth.uid()::text) from unnest(image_paths) p)
 );

drop policy if exists "reports_admin_update" on public.trade_reports;
create policy "reports_admin_update" on public.trade_reports
 for update to authenticated using (public.trade_is_admin())
 with check (public.trade_is_admin());

-- Bucket PRIVADO. Nunca transformar em público.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('trade-evidence','trade-evidence',false,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=false,file_size_limit=5242880,allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists "trade_evidence_upload_owner" on storage.objects;
create policy "trade_evidence_upload_owner" on storage.objects
 for insert to authenticated with check (
 bucket_id='trade-evidence' and (storage.foldername(name))[1]=auth.uid()::text
 and lower(storage.extension(name)) in ('jpg','jpeg','png','webp')
 );
drop policy if exists "trade_evidence_read_owner_admin" on storage.objects;
create policy "trade_evidence_read_owner_admin" on storage.objects
 for select to authenticated using (
 bucket_id='trade-evidence' and (
 (storage.foldername(name))[1]=auth.uid()::text or public.trade_is_admin()
 ));
drop policy if exists "trade_evidence_delete_owner_admin" on storage.objects;
create policy "trade_evidence_delete_owner_admin" on storage.objects
 for delete to authenticated using (
 bucket_id='trade-evidence' and ((storage.foldername(name))[1]=auth.uid()::text or public.trade_is_admin())
 );

-- Provisionamento inicial: crie os usuários no Supabase Authentication > Users;
-- Depois insira perfis no SQL Editor (substitua UUID e nomes):
-- insert into public.trade_profiles(id,display_name,role) values
-- ('UUID-DO-ADMIN','Administrador','admin'),
-- ('UUID-DO-TRADER','Trader 01','trader');
-- Segurança: só um administrador confiável deve criar perfis e marcar roles admin.
