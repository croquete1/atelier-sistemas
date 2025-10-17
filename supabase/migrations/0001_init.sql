-- ==========================
-- EXTENSÕES (se necessário)
-- ==========================
create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";

-- ==========================
-- ENUMs
-- ==========================
create type role as enum ('ADMIN','TECNICO','CHEFE','BALCAO','GESTOR','TESOURARIA','APROVACAO','AUDITOR');
create type origem_rma as enum ('BALCAO','TRANSPORTADORA_TNT_FEDEX','TRANSPORTADORA_CLIENTE');
create type estado_rma as enum ('ABERTO','AGUARDA_PEÇAS','PRONTO_REPARAR','EM_REPARACAO','EM_QA','PRONTO','ENTREGUE','FECHADO');
create type estado_orc as enum ('RASCUNHO','ENVIADO','ACEITE','REJEITADO','EXPIRADO');
create type tipo_linha_orc as enum ('PECA','MO','PORTE','TAXA');
create type tipo_cliente as enum ('EMPRESA','PARTICULAR');

-- ==========================
-- PERFIS (auth.users -> profiles)
-- ==========================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text,
  email text unique,
  role role not null default 'BALCAO',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

-- ==========================
-- CLIENTES / EQUIPAMENTOS
-- ==========================
create table public.cliente (
  id uuid primary key default gen_random_uuid(),
  tipo tipo_cliente not null,
  nif text not null,
  nome text not null,
  email text,
  telefone text,
  morada text,
  cp text,
  localidade text,
  fonte text,
  verificado_em timestamptz,
  created_at timestamptz not null default now()
);
create index if not exists idx_cliente_nif on public.cliente (nif);

create table public.equipamento (
  id uuid primary key default gen_random_uuid(),
  cliente_id uuid not null references public.cliente(id) on delete cascade,
  marca text,
  modelo text,
  sn text,
  created_at timestamptz not null default now()
);
create index if not exists idx_equip_sn on public.equipamento (sn);

-- ==========================
-- RMA + EVENTOS/ESTADOS
-- ==========================
create table public.rma (
  id uuid primary key default gen_random_uuid(),
  numero bigserial unique,
  origem origem_rma not null,
  cliente_id uuid not null references public.cliente(id),
  equipamento_id uuid references public.equipamento(id),
  data_abertura date not null default (now()::date),
  data_limite_30d date not null generated always as ((now()::date) + 30) stored,
  estado estado_rma not null default 'ABERTO',
  garantia_tipo text,
  sla_bucket text,
  criado_por uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.rma_evento (
  id bigserial primary key,
  rma_id uuid not null references public.rma(id) on delete cascade,
  tipo text not null,
  actor_id uuid references public.profiles(id),
  data_hora timestamptz not null default now(),
  payload jsonb,
  ref_id uuid
);
create index if not exists idx_rma_evento_rma on public.rma_evento (rma_id);

create table public.rma_estado_log (
  id bigserial primary key,
  rma_id uuid not null references public.rma(id) on delete cascade,
  de estado_rma,
  para estado_rma not null,
  motivo text,
  actor_id uuid references public.profiles(id),
  data_hora timestamptz not null default now()
);

-- ==========================
-- ORÇAMENTOS
-- ==========================
create table public.orcamento (
  id uuid primary key default gen_random_uuid(),
  rma_id uuid not null references public.rma(id) on delete cascade,
  origem text not null, -- 'DIAGNOSTICO' | 'MANUAL'
  validade_em date,
  estado estado_orc not null default 'RASCUNHO',
  total numeric(12,2) default 0,
  aceite_em timestamptz,
  aceite_por text,
  created_at timestamptz not null default now()
);

create table public.orcamento_linha (
  id bigserial primary key,
  orcamento_id uuid not null references public.orcamento(id) on delete cascade,
  tipo tipo_linha_orc not null,
  artigo_id uuid,
  descricao text not null,
  qtd numeric(12,3) not null default 1,
  preco_unit numeric(12,4) not null default 0,
  iva numeric(5,2) not null default 23
);

-- ==========================
-- FORNECEDORES / PO (multi-RMA)
-- ==========================
create table public.fornecedor (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  nif text,
  email text,
  telefone text,
  created_at timestamptz not null default now()
);

create table public.po (
  id uuid primary key default gen_random_uuid(),
  fornecedor_id uuid not null references public.fornecedor(id),
  numero_interno text not null,
  numero_fornecedor text,
  estado text not null default 'RASCUNHO',
  tracking text,
  eta date,
  notas text,
  created_at timestamptz not null default now()
);

create table public.po_linha (
  id bigserial primary key,
  po_id uuid not null references public.po(id) on delete cascade,
  artigo_id uuid,
  descricao text not null,
  qtd numeric(12,3) not null,
  custo_unit numeric(12,4) not null default 0,
  iva numeric(5,2) not null default 23,
  rma_id uuid references public.rma(id),
  origem text -- 'DIAG' | 'ORC'
);

-- ==========================
-- RECEÇÕES / RESERVAS POR RMA
-- ==========================
create table public.rececao (
  id uuid primary key default gen_random_uuid(),
  po_id uuid not null references public.po(id) on delete cascade,
  data timestamptz not null default now(),
  utilizador_id uuid references public.profiles(id),
  doc_fornecedor text
);

create table public.rececao_linha (
  id bigserial primary key,
  rececao_id uuid not null references public.rececao(id) on delete cascade,
  po_linha_id bigint not null references public.po_linha(id),
  artigo_id uuid,
  qtd numeric(12,3) not null,
  lote_sn text,
  localizacao text
);

create table public.reserva_rma (
  id bigserial primary key,
  rma_id uuid not null references public.rma(id) on delete cascade,
  artigo_id uuid,
  qtd numeric(12,3) not null,
  origem text not null default 'RECECAO',
  created_at timestamptz not null default now()
);

-- ==========================
-- VIEWS (Pesquisa 360)
-- ==========================
create or replace view public.customer_summary as
select
  c.id as cliente_id,
  c.nif, c.nome, c.email, c.telefone,
  count(distinct r.id) filter (where r.estado <> 'FECHADO') as rmas_abertos,
  count(distinct o.id) filter (where o.estado='ENVIADO') as orcamentos_pendentes,
  min(r.data_abertura) as primeiro_rma,
  max(r.created_at) as ultimo_mov
from public.cliente c
left join public.rma r on r.cliente_id = c.id
left join public.orcamento o on o.rma_id = r.id
group by c.id;

create or replace view public.rma_search as
select
  r.id, r.numero, r.estado, r.data_abertura, r.data_limite_30d,
  c.nome as cliente_nome, c.nif,
  e.sn as equipamento_sn, e.marca, e.modelo
from public.rma r
left join public.cliente c on c.id = r.cliente_id
left join public.equipamento e on e.id = r.equipamento_id;

-- ==========================
-- RLS: ativar
-- ==========================
alter table public.profiles enable row level security;
alter table public.cliente enable row level security;
alter table public.equipamento enable row level security;
alter table public.rma enable row level security;
alter table public.rma_evento enable row level security;
alter table public.rma_estado_log enable row level security;
alter table public.orcamento enable row level security;
alter table public.orcamento_linha enable row level security;
alter table public.fornecedor enable row level security;
alter table public.po enable row level security;
alter table public.po_linha enable row level security;
alter table public.rececao enable row level security;
alter table public.rececao_linha enable row level security;
alter table public.reserva_rma enable row level security;

-- Perfis: self + admins/leitura
create policy "profiles_self" on public.profiles
for select using (auth.uid() = id);
create policy "profiles_admin_read" on public.profiles
for select using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('ADMIN','GESTOR','TESOURARIA','AUDITOR')));
create policy "profiles_admin_update" on public.profiles
for update using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('ADMIN')));

-- Cliente: leitura staff ativo; escrita balcão/gestor/admin
create policy "read_staff_cliente" on public.cliente
for select using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_active));
create policy "write_cliente_balcao_gestor" on public.cliente
for insert with check (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('BALCAO','GESTOR','ADMIN')))
for update using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('BALCAO','GESTOR','ADMIN')));

-- Equipamento
create policy "read_staff_equipamento" on public.equipamento
for select using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_active));
create policy "write_equip_balcao_gestor" on public.equipamento
for insert with check (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('BALCAO','GESTOR','ADMIN')))
for update using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('BALCAO','GESTOR','ADMIN')));

-- RMA
create policy "read_staff_rma" on public.rma
for select using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_active));
create policy "create_rma_balcao_gestor" on public.rma
for insert with check (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('BALCAO','GESTOR','ADMIN')));
create policy "update_rma_tecnico_chefe_gestor" on public.rma
for update using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('TECNICO','CHEFE','GESTOR','ADMIN')));

-- Orçamento
create policy "read_staff_orc" on public.orcamento
for select using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_active));
create policy "write_orc_balcao_chefegestor" on public.orcamento
for insert with check (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('BALCAO','CHEFE','GESTOR','ADMIN')))
for update using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('BALCAO','CHEFE','GESTOR','ADMIN')));

-- PO / Receção / Reserva (simplificado; apertar depois por coluna/estado)
create policy "read_staff_po" on public.po
for select using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_active));
create policy "write_po_gestor" on public.po
for insert with check (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('GESTOR','ADMIN')))
for update using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('GESTOR','ADMIN')));

create policy "read_staff_rececao" on public.rececao
for select using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_active));
create policy "write_rececao_gestor" on public.rececao
for insert with check (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('GESTOR','ADMIN')))
for update using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('GESTOR','ADMIN')));

create policy "read_staff_reserva" on public.reserva_rma
for select using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.is_active));
create policy "write_reserva_gestor" on public.reserva_rma
for insert with check (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('GESTOR','ADMIN')))
for update using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.role in ('GESTOR','ADMIN')));

-- FIM
