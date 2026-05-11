# PGR — Programa de Gerenciamento de Riscos

## Base legal
NR-01 (2025) — obrigatório para todas as empresas com empregados CLT.

## Estrutura do PGR no SGS (pgr.html)
1. **Capa** — empresa, responsável técnico, data
2. **Sumário**
3. **Identificação da empresa** — CNAE, grau de risco, SESMT
4. **Inventário de riscos por GHE** — agrupamento por Grupo Homogêneo de Exposição
5. **Matriz de EPI por GHE**
6. **Avaliação Psicossocial** (se houver campanha encerrada)
7. **Plano de Ação**

## GHE — Grupo Homogêneo de Exposição
- **O que é:** agrupamento de funções com perfil de risco similar
- **Como o SGS calcula:** agrupa funções pela assinatura `risco_id:nivel_risco`
- **Nomenclatura:** GHE-01, GHE-02... (sem nome customizado — decisão de simplicidade)
- **Anti-órfão:** header GHE + primeiro risco renderizados juntos antes de quebrar página

## Hierarquia de controles (NR-01 obrigatória)
1. Eliminação
2. Substituição
3. Engenharia
4. Administrativa
5. EPI

## Card de risco no PGR
- Linha 1: categoria + perigo (contexto, pequeno)
- Linha 2: nome do risco + nível (protagonista)
- Linha 3: probabilidade, severidade, expostos
- Linha 4: fonte geradora, via de absorção, limite de tolerância, metodologia, exposição
- Linha 5: danos à saúde
- Linha 6: medidas de controle por nível hierárquico

## Campos editáveis por instância (catálogo como base, instância sobrescreve)
- `fonte_geradora_especifica` (sobrescreve `fonte_geradora` do catálogo)
- `via_absorcao_custom`
- `limite_tolerancia_custom`
- `metodologia_avaliacao_custom`

## Integração com psicossocial
- Se há campanha encerrada: bloco NR-01 aparece no PGR
- Mostra: base legal, metodologia usada, nome do aplicador
- Tabela por função: 8 blocos do Checklist NR-01 ou 23 dimensões do COPSOQ
