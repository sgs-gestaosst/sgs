# Status dos Módulos SGS

## ✅ Módulos Completos

### Psicossocial v2
**Arquivos:** `psicossocial_campanhas.html`, `psicossocial_responder.html`
**Metodologias:** COPSOQ-III Curta (23 itens), COPSOQ-III Média (76 itens/23 dim), Checklist NR-01 (26 fatores/8 blocos)
**Decisões:**
- Respostas COPSOQ Média em `respostas_copsoq.respostas_json` (JSONB)
- Checklist NR-01 usa tabelas próprias: `checklist_nr01_respostas` e `checklist_nr01_resultados`
- Modo manual: `?modo=manual` na URL bypassa "já respondeu"
- Anonimato: vinculado à função, sem funcionario_id
- Grupos < 5: banner amarelo "interpretar com cautela"
- Integração PGR: bloco psicossocial com base legal + resultados por função
- Relatório standalone: botão "📄 Relatório" em campanhas encerradas
- RLS: policies em checklist_nr01_respostas/resultados; trigger com SECURITY DEFINER

### Planos e Assinaturas
**Arquivos:** `trial_check.js`, `plano_utils.js`, `assinar.html`, `index.html`
**Modelo:** Free(R$0) / Starter(R$79) / Pro(R$279) / Business(R$549) / Enterprise(R$949)
**Decisões:**
- Trigger `trg_novo_usuario` cria plano Free no signup (INSERT OR UPDATE)
- SUPERADMIN bypassa tudo: `sgs.gestaosst@gmail.com`
- Free → deixa passar, banner suave
- Suspenso/Cancelado → overlay de bloqueio
- Limites NUNCA hardcodados — sempre via `plano_utils.js`
- Backfill: trials expirados → Free; trials vivos → Starter Ativo

### Riscos v2 + GHE
**Arquivos:** `riscos.html`
**Funcionalidades:** GHE automático no PGR, inventário NR-01 2025, campos de exposição, campos customizáveis
**Colunas novas em setor_riscos/funcao_riscos:** fonte_geradora_especifica, tipo_avaliacao, tempo_exposicao_horas_dia, frequencia_dias_semana, valor_medido, limite_tolerancia_custom, via_absorcao_custom, metodologia_avaliacao_custom
**Decisões:**
- GHE: agrupa funções por assinatura `risco_id:nivel_risco`
- Anti-órfão: header GHE + primeiro risco medidos juntos
- Campos do catálogo editáveis por instância via campos _custom

### EPI / CAEPI
**Arquivos:** `epis.html`
**Base CAEPI:** ~96k registros MTE, importação semanal via GitHub Actions (segunda 3h UTC)
**Descobertas críticas:**
- `SITUACAO` do MTE pode estar desatualizado — não usar como fonte de validade
- `data_validade` é data de emissão, NÃO o vencimento real
- Única fonte confiável: `consultaca.com/{numero_ca}`
- Badge 🟢/🔴 calculado pela data informada pelo técnico, não pelo MTE
- `epi_nome` tem prioridade sobre `epi_id` no PGR

### IA Copilot
**Arquivo:** `ia_copilot.js` (incluído via `?vN` para cache bust)
**Provider:** Groq API — `llama-3.1-8b-instant` — URL: `https://api.groq.com/openai/v1/chat/completions`
**Funções disponíveis:**
- `ia_sugerirSetor(nome)` → descrição + 6 checkboxes de agentes
- `ia_sugerirFuncao(nome)` → descrição + 5 checkboxes de condições especiais
- `ia_sugerirRiscos(nomeCtx, tipoCtx, catalogo)` → array de risco IDs
- `ia_sugerirMedida(nomeRisco, catRisco, tipoMedida)` → texto da medida
**Implementado em:** `empresa_detalhe.html` (setor + função), `riscos.html` (riscos + medidas)
**Pendente:** ações.html (título, descrição, indicador, prazo)
**Chave:** no vault — NUNCA commitar sem allow no GitHub security

## 🔄 Módulos em Uso (melhorias contínuas)

### PGR
**Arquivo:** `pgr.html`
**Seções:** Capa → Sumário → Identificação → Caracterização → SESMT → Metodologia P×S → Critérios por Categoria → Inventário por GHE → Matriz EPI → Psicossocial (se houver) → Plano de Ação → Monitoramento → Participação (se houver) → Contratadas → Versões
**Status:** ✅ Revisão completa de design e paginação concluída (2026-05-14)

**Revisão de design e paginação (2026-05-14):**
- Agente 08 — Design e Paginação criado
- Capa: empresa em destaque + elaboradora discreta no rodapé (lógica inteligente — só aparece se diferente)
- Logo da empresa: clicável para upload diretamente na capa
- Fontes: corpo 10pt, tabelas 9pt, todo #9ca3af→#6b7280 escurecido
- @media print: contraste forçado para todos os elementos
- Paginação: ALTURA_UTIL_PX 210mm→200mm (conservador), container 168mm→160mm
- Plano de ação: substituído contagem fixa de linhas por medição real de altura
- Seções vazias omitidas: psicossocial e participação não aparecem se sem dados
- Critérios por categoria: separados em página 2 da Metodologia

**Fases implementadas:**
- Fase 1: Matriz P×S, data elaboração, indicador no plano, CSS impressão
- Fase 2: Critérios por categoria, GHE nomeável, eficácia das medidas, nível residual
- Fase 3: Histórico de acidentes/doenças por risco, confirmação digital de participação

**Pendente:**
- ~~Visualização de respostas individuais do psicossocial~~ ✅ concluído (2026-05-14) — modal decodificado por bloco/dimensão, escala colorida, funciona para Checklist NR-01, COPSOQ-III Média e Curta
- Revisão PCMSO, AET, LTCAT

### eSocial
**Arquivos:** `esocial_s2220.html` (ASO), `esocial_s2240.html` (exposição)
**Status:** parcial — geração básica implementada, validação completa pendente

## ⚠️ Módulos que Precisam de Revisão

| Módulo | Arquivo | Pendência |
|---|---|---|
| AET | `aet.html` | Validar conformidade com NR-17 atualizada |
| LTCAT | `ltcat.html` | Revisar campos obrigatórios |
| PCMSO | `pcmso.html` | Revisar conformidade NR-07 |
| Treinamentos | `treinamentos.html` | Integração e-Social pendente |
| Checklists | `checklists.html` | Revisar fluxo |

## 📋 Backlog conhecido
- Restrição de domínio na chave Groq (quando comprar domínio próprio)
- Sugestão de perigos/riscos por função (além do que a IA já faz)
- Integração IA em `acoes.html`
- Validação completa do PGR contra NR-01 2025
