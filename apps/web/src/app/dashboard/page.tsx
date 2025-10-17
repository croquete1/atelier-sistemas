import { createClientServer } from '@/lib/supabase-client'

export default async function Dashboard() {
  const supa = createClientServer()
  const { data: summary } = await supa.from('customer_summary').select('*').limit(5)
  const { data: rmas } = await supa.from('rma_search').select('*').order('data_abertura', { ascending: false }).limit(10)

  return (
    <main className="p-6 space-y-6">
      <h1 className="text-2xl font-semibold">Dashboard</h1>
      <section>
        <h2 className="font-medium mb-2">Clientes (resumo)</h2>
        <ul className="list-disc pl-5">
          {summary?.map((c:any)=>(
            <li key={c.cliente_id}>{c.nome} — RMA abertos: {c.rmas_abertos} — Orç. pendentes: {c.orcamentos_pendentes}</li>
          ))}
        </ul>
      </section>
      <section>
        <h2 className="font-medium mb-2">Últimos RMA</h2>
        <ul className="list-disc pl-5">
          {rmas?.map((r:any)=>(
            <li key={r.id}>#{r.numero} — {r.cliente_nome} — {r.estado} — limite 30d: {r.data_limite_30d}</li>
          ))}
        </ul>
      </section>
    </main>
  )
}
