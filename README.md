# Atelier Sistemas — MVP (Next.js + Supabase)

## 1) Setup rápido
1. Criar projeto no Supabase (STAGING e PROD, se quiser).
2. No Supabase, abrir **SQL Editor** e executar o conteúdo de `supabase/migrations/0001_init.sql`.
3. Em `apps/web`, criar `.env.local` com:
NEXT_PUBLIC_SUPABASE_URL=...
NEXT_PUBLIC_SUPABASE_ANON_KEY=...

APENAS NO SERVIDOR (server actions/route handlers)

SUPABASE_SERVICE_ROLE_KEY=...

4. `cd apps/web && npm i && npm run dev`.

## 2) Deploy (opcional)
- **Vercel**: root = `apps/web`; definir envs (Preview → STAGING; Production → PROD).
- CI de migrations com `supabase.yml` (ver `.github/workflows`).

## 3) Pastas importantes
- `apps/web/src/app` — páginas Next.js (App Router)
- `apps/web/src/lib` — cliente Supabase (browser/server)
- `supabase/migrations/0001_init.sql` — esquema inicial + RLS

---

## 4) MVP incluído
- Autenticação com Supabase Auth (email/password).
- RMA: criar (origem obrigatória), listar/pesquisar, detalhe com **timeline** básica.
- Orçamento base (estrutura).
- Procurement/PO (estrutura tabular).
- Receção e reservas por RMA (estrutura).
- Pesquisa 360: por nº RMA, NIF/nome cliente, SN, modelo.

---

## 5) Notas
- RLS ativa em todas as tabelas.
- **Nunca** colocar `SUPABASE_SERVICE_ROLE_KEY` no browser.
- Buckets (a criar no Supabase Storage): `rma-fotos`, `artigos-fotos`, `docs-pdf`.
