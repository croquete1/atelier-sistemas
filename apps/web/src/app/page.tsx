import Link from 'next/link'

export default function Home() {
  return (
    <main className="p-6 space-y-4">
      <h1 className="text-2xl font-semibold">Atelier — MVP</h1>
      <ul className="list-disc pl-6">
        <li><Link className="text-blue-600 underline" href="/login">Login</Link></li>
        <li><Link className="text-blue-600 underline" href="/dashboard">Dashboard</Link></li>
        <li><Link className="text-blue-600 underline" href="/rma/novo">Criar RMA</Link></li>
        <li><Link className="text-blue-600 underline" href="/pesquisa">Pesquisa 360</Link></li>
      </ul>
    </main>
  )
}
