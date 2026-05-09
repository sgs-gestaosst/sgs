-- ============================================================
-- Migração v2 — Módulo de Riscos (GHE + Exposição + Quantitativo + Medidas)
-- Executar no Supabase SQL Editor (uma vez)
-- ============================================================

-- ── 1. Novos campos em setor_riscos ──────────────────────────
ALTER TABLE public.setor_riscos
  ADD COLUMN IF NOT EXISTS fonte_geradora_especifica  TEXT,
  ADD COLUMN IF NOT EXISTS tipo_avaliacao             VARCHAR(20)  CHECK (tipo_avaliacao IN ('Qualitativa','Quantitativa')),
  ADD COLUMN IF NOT EXISTS tempo_exposicao_horas_dia  NUMERIC(4,1),
  ADD COLUMN IF NOT EXISTS frequencia_dias_semana     INTEGER      CHECK (frequencia_dias_semana BETWEEN 1 AND 7),
  ADD COLUMN IF NOT EXISTS valor_medido               NUMERIC(10,4),
  ADD COLUMN IF NOT EXISTS unidade_medida             VARCHAR(30),
  ADD COLUMN IF NOT EXISTS limite_tolerancia_nr       VARCHAR(100),
  ADD COLUMN IF NOT EXISTS data_medicao               DATE,
  ADD COLUMN IF NOT EXISTS responsavel_medicao        VARCHAR(200),
  ADD COLUMN IF NOT EXISTS medida_elim_responsavel    VARCHAR(200),
  ADD COLUMN IF NOT EXISTS medida_elim_prazo          DATE,
  ADD COLUMN IF NOT EXISTS medida_subs_responsavel    VARCHAR(200),
  ADD COLUMN IF NOT EXISTS medida_subs_prazo          DATE,
  ADD COLUMN IF NOT EXISTS medida_eng_responsavel     VARCHAR(200),
  ADD COLUMN IF NOT EXISTS medida_eng_prazo           DATE,
  ADD COLUMN IF NOT EXISTS medida_adm_responsavel     VARCHAR(200),
  ADD COLUMN IF NOT EXISTS medida_adm_prazo           DATE;

-- ── 2. Novos campos em funcao_riscos ─────────────────────────
ALTER TABLE public.funcao_riscos
  ADD COLUMN IF NOT EXISTS fonte_geradora_especifica  TEXT,
  ADD COLUMN IF NOT EXISTS tipo_avaliacao             VARCHAR(20)  CHECK (tipo_avaliacao IN ('Qualitativa','Quantitativa')),
  ADD COLUMN IF NOT EXISTS tempo_exposicao_horas_dia  NUMERIC(4,1),
  ADD COLUMN IF NOT EXISTS frequencia_dias_semana     INTEGER      CHECK (frequencia_dias_semana BETWEEN 1 AND 7),
  ADD COLUMN IF NOT EXISTS valor_medido               NUMERIC(10,4),
  ADD COLUMN IF NOT EXISTS unidade_medida             VARCHAR(30),
  ADD COLUMN IF NOT EXISTS limite_tolerancia_nr       VARCHAR(100),
  ADD COLUMN IF NOT EXISTS data_medicao               DATE,
  ADD COLUMN IF NOT EXISTS responsavel_medicao        VARCHAR(200),
  ADD COLUMN IF NOT EXISTS medida_elim_responsavel    VARCHAR(200),
  ADD COLUMN IF NOT EXISTS medida_elim_prazo          DATE,
  ADD COLUMN IF NOT EXISTS medida_subs_responsavel    VARCHAR(200),
  ADD COLUMN IF NOT EXISTS medida_subs_prazo          DATE,
  ADD COLUMN IF NOT EXISTS medida_eng_responsavel     VARCHAR(200),
  ADD COLUMN IF NOT EXISTS medida_eng_prazo           DATE,
  ADD COLUMN IF NOT EXISTS medida_adm_responsavel     VARCHAR(200),
  ADD COLUMN IF NOT EXISTS medida_adm_prazo           DATE;

-- ── 3. Tabela ghe_nomes (nomes editáveis pelo técnico) ────────
CREATE TABLE IF NOT EXISTS public.ghe_nomes (
  id            SERIAL PRIMARY KEY,
  empresa_id    INTEGER NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  ghe_codigo    VARCHAR(20) NOT NULL,
  ghe_nome      VARCHAR(200),
  criado_em     TIMESTAMP DEFAULT NOW(),
  atualizado_em TIMESTAMP DEFAULT NOW(),
  UNIQUE(empresa_id, ghe_codigo)
);

-- RLS para ghe_nomes
ALTER TABLE public.ghe_nomes ENABLE ROW LEVEL SECURITY;

CREATE POLICY ghe_nomes_select ON public.ghe_nomes
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY ghe_nomes_insert ON public.ghe_nomes
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY ghe_nomes_update ON public.ghe_nomes
  FOR UPDATE USING (auth.uid() IS NOT NULL);

-- ── Verificação ───────────────────────────────────────────────
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'setor_riscos'
  AND column_name IN (
    'fonte_geradora_especifica','tipo_avaliacao',
    'tempo_exposicao_horas_dia','frequencia_dias_semana',
    'valor_medido','medida_elim_responsavel','medida_elim_prazo'
  )
ORDER BY column_name;
