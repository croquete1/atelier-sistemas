import { createClientServer } from '@/lib/supabase-client'

export default async function PesquisaPage({ searchParams }: { searchParams: { q?: string } }) {
  const q = (searchParams.q ?? '').trim()
  const supa = createClientServer()
  let rmas:any[] = []
  if(q) {
    const maybeNum = Number(q)
    const queries = [
      Number.isFinite(maybeNum) ? supa.from('rma_search').select('*').eq('numero', maybeNum).limit(20) : null,
      supa.from('rma_search').select('*').ilike('cliente_nome', `%${q}%`).limit(20),
      supa.from('rma_search').select('*').ilike('nif', `%${q}%`).limit(20),
      supa.from('rma_search').select('*').ilike('equipamento_sn', `%${q}%`).limit(20),
    ]
    const results = await Promise.all(queries.map(qry => qry ?? Promise.resolve({ data: [] } as any)))
    rmas = results.flatMap(res => res.data ?? [])
    const map = new Map(rmas.map(r=>[r.id, r]))
    rmas = [...map.values()]
  }
  return (
    <main className="p-6 space-y-4">
      <form className="mb-4">
        <input name="q" defaultValue={q} placeholder="Nº RMA / NIF / Nome / SN / Modelo" className="border p-2 w-full max-w-xl" />
      </form>
      {!q && <p className="text-slate-600">Introduza um termo para pesquisar…</p>}
      {q && (
        <ul className="border rounded divide-y">
          {rmas.map((r:any)=>(
            <li key={r.id} className="p-3">
              <a className="text-blue-600 underline" href={`/rma/${r.id}`}>RMA #{r.numero}</a> — {r.cliente_nome} — {r.estado} — Limite: {r.data_limite_30d}
            </li>
          ))}
          {rmas.length===0 && <li className="p-3 text-slate-600">Sem resultados…</li>}
        </ul>
      )}
    </main>
  )
}
