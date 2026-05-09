-- ============================================================
-- Migração v3 — Campos editáveis por instância (via_absorcao, limite, metodologia)
-- Executar no Supabase SQL Editor (uma vez)
-- ============================================================

ALTER TABLE public.setor_riscos
  ADD COLUMN IF NOT EXISTS via_absorcao_custom        TEXT,
  ADD COLUMN IF NOT EXISTS limite_tolerancia_custom   TEXT,
  ADD COLUMN IF NOT EXISTS metodologia_avaliacao_custom TEXT;

ALTER TABLE public.funcao_riscos
  ADD COLUMN IF NOT EXISTS via_absorcao_custom        TEXT,
  ADD COLUMN IF NOT EXISTS limite_tolerancia_custom   TEXT,
  ADD COLUMN IF NOT EXISTS metodologia_avaliacao_custom TEXT;

-- Verificação
SELECT column_name FROM information_schema.columns
WHERE table_name = 'setor_riscos'
  AND column_name IN ('via_absorcao_custom','limite_tolerancia_custom','metodologia_avaliacao_custom')
ORDER BY column_name;
