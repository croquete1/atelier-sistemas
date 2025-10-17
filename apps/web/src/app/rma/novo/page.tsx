'use client'
import { useState } from 'react'
import { createClientBrowser } from '@/lib/supabase-client'

export default function NovoRMA() {
  const supa = createClientBrowser()
  const [form, setForm] = useState({
    origem: 'BALCAO',
    cliente_nome: '',
    cliente_nif: '',
    tipo_cliente: 'EMPRESA',
    marca: '', modelo: '', sn: ''
  })
  const [msg, setMsg] = useState<string | null>(null)

  function upd(k:string, v:string){ setForm(s=>({ ...s, [k]: v })) }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault()
    setMsg(null)
    // criar cliente (ou localizar por NIF)
    let { data: cli } = await supa.from('cliente').select('id').eq('nif', form.cliente_nif).maybeSingle()
    if(!cli){
      const ins = await supa.from('cliente').insert({
        tipo: form.tipo_cliente, nif: form.cliente_nif, nome: form.cliente_nome
      }).select('id').single()
      if(ins.error) return setMsg(ins.error.message)
      cli = ins.data
    }
    // criar equipamento
    const eq = await supa.from('equipamento').insert({
      cliente_id: cli.id, marca: form.marca, modelo: form.modelo, sn: form.sn
    }).select('id').single()
    if(eq.error) return setMsg(eq.error.message)
    // criar RMA
    const r = await supa.from('rma').insert({
      origem: form.origem, cliente_id: cli.id, equipamento_id: eq.data.id
    }).select('numero').single()
    if(r.error) return setMsg(r.error.message)
    setMsg(`RMA criado com sucesso: #${r.data.numero}`)
  }

  return (
    <main className="p-6 max-w-2xl mx-auto space-y-4">
      <h1 className="text-2xl font-semibold">Novo RMA</h1>
      <form className="grid grid-cols-2 gap-3" onSubmit={onSubmit}>
        <label className="col-span-2">Origem
          <select className="border p-2 w-full" value={form.origem} onChange={e=>upd('origem', e.target.value)}>
            <option value="BALCAO">Balcão</option>
            <option value="TRANSPORTADORA_TNT_FEDEX">Transportadora – TNT/FedEx</option>
            <option value="TRANSPORTADORA_CLIENTE">Transportadora do cliente</option>
          </select>
        </label>
        <label>Tipo Cliente
          <select className="border p-2 w-full" value={form.tipo_cliente} onChange={e=>upd('tipo_cliente', e.target.value)}>
            <option value="EMPRESA">Empresa</option>
            <option value="PARTICULAR">Particular</option>
          </select>
        </label>
        <label>NIF
          <input className="border p-2 w-full" value={form.cliente_nif} onChange={e=>upd('cliente_nif', e.target.value)} />
        </label>
        <label className="col-span-2">Nome
          <input className="border p-2 w-full" value={form.cliente_nome} onChange={e=>upd('cliente_nome', e.target.value)} />
        </label>
        <label>Marca
          <input className="border p-2 w-full" value={form.marca} onChange={e=>upd('marca', e.target.value)} />
        </label>
        <label>Modelo
          <input className="border p-2 w-full" value={form.modelo} onChange={e=>upd('modelo', e.target.value)} />
        </label>
        <label className="col-span-2">SN
          <input className="border p-2 w-full" value={form.sn} onChange={e=>upd('sn', e.target.value)} />
        </label>
        <button className="bg-blue-600 text-white px-4 py-2 rounded col-span-2">Criar</button>
      </form>
      {msg && <p className="text-green-700">{msg}</p>}
    </main>
  )
}
