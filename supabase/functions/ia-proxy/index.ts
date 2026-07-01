// ── IA PROXY ──────────────────────────────────────────────────
// Recebe { prompt }, valida a sessão do usuário e repassa ao Groq
// usando a chave guardada em GROQ_API_KEY (secret do projeto).

import { createClient } from 'jsr:@supabase/supabase-js@2'

const GROQ_URL = 'https://api.groq.com/openai/v1/chat/completions'

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms))

async function chamarGroq(prompt: string, apiKey: string, tentativa = 0): Promise<Response> {
  const res = await fetch(GROQ_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + apiKey,
    },
    body: JSON.stringify({
      model: 'llama-3.1-8b-instant',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.2,
      max_tokens: 512,
    }),
  })

  if (res.status === 429 && tentativa < 3) {
    // Respeita o retry-after do Groq se disponível, senão backoff exponencial
    const retryAfter = res.headers.get('retry-after')
    const espera = retryAfter ? parseFloat(retryAfter) * 1000 : Math.pow(2, tentativa) * 1500
    await sleep(espera)
    return chamarGroq(prompt, apiKey, tentativa + 1)
  }

  return res
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS })
  }

  const headers = { ...CORS_HEADERS, 'Content-Type': 'application/json' }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'method_not_allowed' }), { status: 405, headers })
  }

  const authHeader = req.headers.get('Authorization')
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'missing_auth' }), { status: 401, headers })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } }
  )

  const { data: { user }, error: authError } = await supabase.auth.getUser()
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'unauthorized' }), { status: 401, headers })
  }

  const body = await req.json().catch(() => ({}))

  // ── Rota: consulta CNPJ via BrasilAPI (server-side, sem CORS) ──
  if (body.cnpj) {
    const cnpj = String(body.cnpj).replace(/\D/g, '')
    if (cnpj.length !== 14) {
      return new Response(JSON.stringify({ error: 'cnpj_invalido' }), { status: 400, headers })
    }
    const brasilRes = await fetch(`https://brasilapi.com.br/api/cnpj/v1/${cnpj}`, {
      headers: { 'Accept': 'application/json', 'User-Agent': 'SGS-SST/1.0' },
    })
    const data = await brasilRes.json().catch(() => ({}))
    return new Response(JSON.stringify(data), { status: brasilRes.status, headers })
  }

  // ── Rota: sugestão IA via Groq ──
  const { prompt } = body
  if (!prompt || typeof prompt !== 'string') {
    return new Response(JSON.stringify({ error: 'invalid_request' }), { status: 400, headers })
  }

  const groqRes = await chamarGroq(prompt, Deno.env.get('GROQ_API_KEY')!)
  const data = await groqRes.json().catch(() => ({}))

  if (!groqRes.ok) {
    return new Response(JSON.stringify({ error: data.error?.message || 'groq_error' }), { status: groqRes.status, headers })
  }

  const text = data.choices?.[0]?.message?.content || ''
  return new Response(JSON.stringify({ text }), { status: 200, headers })
})
