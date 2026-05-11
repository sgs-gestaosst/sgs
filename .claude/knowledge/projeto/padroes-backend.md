# Padrões Backend — SGS (Supabase)

## Conexão
```javascript
const SUPA_URL = 'https://ookqdukeulwcnhilbgbo.supabase.co';
const SUPA_KEY = 'sb_publishable_l9NggU-e1bgt7CnrYUWo4w_AMoaJa2e';

// Helper de headers (padrão em todas as páginas)
function h2() {
  return {
    'apikey': SUPA_KEY,
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  };
}
```

## Padrão de query
```javascript
// SELECT
const res = await fetch(
  `${SUPA_URL}/rest/v1/tabela?campo=eq.valor&select=col1,col2&order=col1.asc`,
  { headers: h2() }
);
const data = await res.json();

// INSERT com retorno
const res = await fetch(`${SUPA_URL}/rest/v1/tabela`, {
  method: 'POST',
  headers: { ...h2(), 'Prefer': 'return=representation' },
  body: JSON.stringify(payload)
});

// UPDATE
const res = await fetch(`${SUPA_URL}/rest/v1/tabela?id=eq.${id}`, {
  method: 'PATCH',
  headers: { ...h2(), 'Prefer': 'return=representation' },
  body: JSON.stringify(payload)
});

// Soft delete (padrão do projeto — nunca DELETE real)
body: JSON.stringify({ ativo: false })
```

## Padrão de RLS
- Todas as tabelas operacionais têm RLS ativo
- Isolamento por `empresa_id` — usuário só vê dados da sua empresa
- SUPERADMIN (`sgs.gestaosst@gmail.com`) bypassa via `trial_check.js`
- Tabelas públicas sem RLS: `ca_epi` (dados públicos MTE), `riscos`, `categorias_risco`, `perigos`, `cbo`

## Padrão de migration
```sql
-- SEMPRE usar IF NOT EXISTS para não quebrar produção
ALTER TABLE tabela
  ADD COLUMN IF NOT EXISTS nova_coluna TIPO DEFAULT valor;

-- Nunca DROP sem confirmar com usuário
-- Nunca ALTER TYPE sem migrar dados antes
```

## Funções RPC (stored procedures)
```javascript
const res = await fetch(`${SUPA_URL}/rest/v1/rpc/nome_funcao`, {
  method: 'POST',
  headers: h2(),
  body: JSON.stringify({ p_empresa_id: parseInt(empresaId) })
});
```

## Padrão de payload
```javascript
// Campos de controle sempre presentes
const payload = {
  empresa_id: parseInt(empresaId),  // sempre parseInt
  // ... campos do formulário
  ativo: true,
  atualizado_em: new Date().toISOString()  // em updates
};

// Campos opcionais: usar || null (nunca string vazia no banco)
responsavel: document.getElementById('x').value.trim() || null
```

## Propagação setor → função (padrão de riscos)
```javascript
// Quando risco é adicionado ao setor, propaga para funções do setor
await propagarRiscoParaFuncoes(novoSetorRisco);
// Medidas do setor também propagam para funcao_riscos
// Ver riscos.html — função propagarRiscoParaFuncoes()
```

## GitHub Actions — CAEPI
- Workflow: `.github/workflows/importar-caepi.yml`
- Agenda: toda segunda 3h UTC
- Secrets necessários: `SUPA_URL`, `SUPA_SERVICE_KEY`
- Formato fonte MTE: RAR com TXT pipe-delimited, encoding latin-1
- Coluna CA: `#NRREGISTROCA` (com # prefixo)

## Supabase Auth
- Token: `localStorage.getItem('sgs_token')`
- Sessão gerenciada pelo Supabase JS SDK
- Signup → trigger `trg_novo_usuario` → cria assinatura Free automaticamente
