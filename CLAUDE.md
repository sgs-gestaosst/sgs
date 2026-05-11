# SGS — Sistema de Gestão em SST

## O que é este projeto
SaaS de Saúde e Segurança do Trabalho (SST) para técnicos e consultores. Gera PGR, PCMSO, LTCAT e documentos legais com base em dados cadastrados. Modelo freemium com 5 planos.

## Stack
- **Frontend:** HTML puro + CSS embutido por página (sem framework, sem build)
- **Backend:** Supabase (PostgreSQL 17 + Auth + Storage + RLS)
- **Hospedagem:** GitHub Pages → `sgs-gestaosst.github.io/sgs`
- **Pagamento:** Mercado Pago (mp_assinatura_id, mp_payment_id)
- **IA:** Groq API (llama-3.1-8b-instant) via `ia_copilot.js`

## Localização dos arquivos
- Páginas: `C:\Users\DELL\sgs\*.html` (~30 páginas)
- Schema completo: `C:\Users\DELL\sgs\notes\notas\schema.sql`
- Credenciais: `C:\Users\DELL\vault\sgs\credenciais.md`
- Agentes: `C:\Users\DELL\sgs\.claude\agents\`
- Base de conhecimento: `C:\Users\DELL\sgs\.claude\knowledge\`

## Hierarquia do banco
```
empresas → unidades → setores → funcoes → funcionarios
                ↓
         setor_riscos → funcao_riscos → funcionario_riscos
```

## Regras críticas
- **SUPERADMIN:** `sgs.gestaosst@gmail.com` bypassa toda verificação de plano
- **RLS ativo** em todas as tabelas operacionais — isolamento por `empresa_id`
- **Limites de plano** sempre via `plano_utils.js` — NUNCA hardcodado
- **Migrations:** sempre usar `ADD COLUMN IF NOT EXISTS` — banco em produção
- **Cache bust:** incrementar `?vN` no script tag do `ia_copilot.js` a cada deploy

## Arquivos JS compartilhados (incluir em páginas protegidas)
- `trial_check.js` — verifica auth e status da assinatura
- `plano_utils.js` — limites de plano, modal de upgrade
- `ia_copilot.js` — copilot IA (Groq), funções: `ia_sugerirSetor`, `ia_sugerirFuncao`, `ia_sugerirRiscos`, `ia_sugerirMedida`

## Conexão Supabase
- URL: `https://ookqdukeulwcnhilbgbo.supabase.co`
- Key pública: `sb_publishable_l9NggU-e1bgt7CnrYUWo4w_AMoaJa2e`
- Sempre usar `Authorization: Bearer ${token}` com token do localStorage

## Planos ativos
| Plano | Preço | Empresas | Funcionários | eSocial |
|---|---|---|---|---|
| Free | R$0 | 2 | 25 | Não |
| Starter | R$79 | 8 | 120 | Sim |
| Pro | R$279 | 15 | 300 | Sim |
| Business | R$549 | 60 | 1.500 | Sim |
| Enterprise | R$949 | ilimitado | ilimitado | Sim |

## Status dos módulos
Ver detalhes em `.claude/knowledge/projeto/modulos.md`

| Módulo | Arquivo | Status |
|---|---|---|
| Psicossocial v2 | psicossocial_campanhas.html + psicossocial_responder.html | ✅ Completo |
| Riscos v2 + GHE | riscos.html | ✅ Completo |
| EPI / CAEPI | epis.html | ✅ Completo |
| Planos / Assinaturas | assinar.html + trial_check.js + plano_utils.js | ✅ Completo |
| IA Copilot | ia_copilot.js | ✅ Ativo (setor, função, riscos, medidas) |
| PGR | pgr.html | 🔄 Em uso, melhorias contínuas |
| eSocial | esocial_s2220.html + esocial_s2240.html | 🔄 Parcial |
| AET | aet.html | ⚠️ Revisar |
| LTCAT | ltcat.html | ⚠️ Revisar |
| PCMSO | pcmso.html | ⚠️ Revisar |

## Agentes disponíveis
Ao iniciar qualquer tarefa complexa, consultar `.claude/agents/` para decidir qual agente acionar.

| Agente | Quando acionar |
|---|---|
| 01-arquiteto | Antes de implementar qualquer feature nova |
| 02-desenvolvedor | Implementação de código |
| 03-nr-compliance | Feature toca área regulada por NR |
| 04-sst-especialista | Dúvida técnica de SST ou domínio |
| 05-revisor | Antes de qualquer commit |
| 06-pesquisador | Informação externa necessária |

## Convenções de código
- CSS: variáveis em `:root` — `--bg`, `--surface`, `--border`, `--accent`, `--text`, etc.
- Modais: classe `modal-overlay` + `modal-overlay.show`
- Status bars: função `setStatus(id, 'success'|'error'|'info', msg)`
- Escape HTML: sempre usar `escHtml()` ou `h()` antes de inserir no DOM
- Datas: formato `YYYY-MM-DD` no banco, `toLocaleDateString('pt-BR')` na UI
