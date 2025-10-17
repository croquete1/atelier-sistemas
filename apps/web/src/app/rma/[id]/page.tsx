import { createClientServer } from '@/lib/supabase-client'
import Link from 'next/link'

export default async function RmaDetalhe({ params }: { params: { id: string } }) {
  const supa = createClientServer()
  const { data: rma } = await supa.from('rma_search').select('*').eq('id', params.id).maybeSingle()
  const { data: eventos } = await supa.from('rma_evento').select('*').eq('rma_id', params.id).order('data_hora', { ascending: false }).limit(50)

  if(!rma) return <main className="p-6">RMA não encontrado.</main>
  return (
    <main className="p-6 space-y-4">
      <h1 className="text-2xl font-semibold">RMA #{rma.numero}</h1>
      <p>Cliente: {rma.cliente_nome} — Estado: <b>{rma.estado}</b> — Limite 30d: {rma.data_limite_30d}</p>
      <Link className="text-blue-600 underline" href="/pesquisa">← voltar à pesquisa</Link>
      <section>
        <h2 className="font-medium mt-4 mb-2">Timeline</h2>
        <ul className="border rounded divide-y">
          {(eventos ?? []).map((e:any)=>(
            <li key={e.id} className="p-3">
              <b>{e.tipo}</b> — {new Date(e.data_hora).toLocaleString()} — actor: {e.actor_id ?? 'sistema'}
            </li>
          ))}
        </ul>
      </section>
    </main>
  )
}
