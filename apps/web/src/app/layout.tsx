import './globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Atelier Sistemas',
  description: 'MVP Assistência Técnica',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="pt">
      <body className="min-h-screen bg-white text-slate-900">{children}</body>
    </html>
  )
}
