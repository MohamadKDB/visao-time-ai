-- Visão do Time — Farol de Backlog
-- Tabela usada pelo fluxo n8n/visao-time.json (ações carregar e salvar).
--
-- Rode isto no banco apontado pela credencial Postgres do n8n.
-- Serve tanto um Postgres próprio quanto o Supabase (SQL Editor).

create table if not exists public.visao_time_backlog (
  id             text primary key default 'atual',
  demandas       jsonb       not null default '[]'::jsonb,
  atualizado_em  timestamptz not null default now(),
  atualizado_por text
);

comment on table  public.visao_time_backlog is
  'Backlog do painel Visão do Time. Uma linha (id = ''atual'') com o estado completo em jsonb.';
comment on column public.visao_time_backlog.demandas is
  'Array de demandas exatamente como o painel serializa. O painel envia o estado inteiro, não diffs.';

-- Não é obrigatório inserir a linha: o `salvar` faz
-- `insert ... on conflict (id) do update`, então ela nasce no primeiro save.
-- Se preferir já ter a linha para inspecionar no banco:
--
--   insert into public.visao_time_backlog (id) values ('atual')
--   on conflict (id) do nothing;


-- ---------------------------------------------------------------------------
-- Opcional: histórico append-only
-- ---------------------------------------------------------------------------
-- A tabela acima guarda só o estado atual — cada save sobrescreve o anterior.
-- Com esta segunda tabela dá para reconstruir a evolução do farol semana a
-- semana. Para usar, acrescente no branch `salvar` do fluxo um nó Postgres com:
--
--   insert into public.visao_time_backlog_hist (demandas, atualizado_por)
--   values ($1::jsonb, $2);

create table if not exists public.visao_time_backlog_hist (
  id             bigserial primary key,
  demandas       jsonb       not null,
  registrado_em  timestamptz not null default now(),
  atualizado_por text
);

create index if not exists visao_time_backlog_hist_registrado_em_idx
  on public.visao_time_backlog_hist (registrado_em desc);


-- ---------------------------------------------------------------------------
-- Se o banco for Supabase: bloqueie a API pública
-- ---------------------------------------------------------------------------
-- No Supabase, toda tabela em `public` fica exposta na API REST. O painel NÃO
-- fala com o Supabase direto — ele passa pelo n8n — então ninguém precisa de
-- acesso via anon key. Ligar RLS sem criar policy nenhuma fecha a porta para
-- anon/authenticated, e a conexão do n8n (role postgres) segue funcionando.

alter table public.visao_time_backlog      enable row level security;
alter table public.visao_time_backlog_hist enable row level security;
