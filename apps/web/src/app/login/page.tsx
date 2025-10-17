'use client'
import { createClientBrowser } from '@/lib/supabase-client'
import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function LoginPage() {
  const supa = createClientBrowser()
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [pass, setPass] = useState('')
  const [err, setErr] = useState<string | null>(null)

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault()
    setErr(null)
    const { error } = await supa.auth.signInWithPassword({ email, password: pass })
    if (error) return setErr(error.message)
    router.push('/dashboard')
  }

  return (
    <main className="p-6 max-w-sm mx-auto">
      <h1 className="text-xl font-semibold mb-4">Entrar</h1>
      <form className="space-y-3" onSubmit={onSubmit}>
        <input className="border p-2 w-full" placeholder="Email" value={email} onChange={e=>setEmail(e.target.value)} />
        <input className="border p-2 w-full" type="password" placeholder="Password" value={pass} onChange={e=>setPass(e.target.value)} />
        {err && <p className="text-red-600 text-sm">{err}</p>}
        <button className="bg-blue-600 text-white px-4 py-2 rounded">Entrar</button>
      </form>
    </main>
  )
}
