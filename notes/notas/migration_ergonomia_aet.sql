-- ═══════════════════════════════════════════════════════
-- MIGRATION: Módulo de Avaliação Ergonômica por Metodologia
-- Data: 2026-06-21
-- ═══════════════════════════════════════════════════════

-- ── 1. NOVA TABELA: aet_metodologias ─────────────────────
CREATE TABLE IF NOT EXISTS public.aet_metodologias (
    id                  SERIAL PRIMARY KEY,
    aet_id              INTEGER NOT NULL REFERENCES public.aet_avaliacoes(id) ON DELETE CASCADE,
    empresa_id          INTEGER NOT NULL REFERENCES public.empresas(id),
    metodologia         VARCHAR(20) NOT NULL,
    -- OCRA_CHECKLIST | RULA | JSI | OWAS | NIOSH | REBA | QUALITATIVA_NR17
    membro_avaliado     VARCHAR(100),
    tarefa              VARCHAR(300),
    score_total         NUMERIC(8,2),
    nivel_risco         VARCHAR(30),
    -- Aceitável | Muito Leve | Leve | Médio | Alto | Muito Alto
    nivel_acao          VARCHAR(10),
    -- 1 | 2 | 3 | 4
    dados_json          JSONB,
    -- Campos específicos de cada metodologia (ver documentação)
    recomendacoes       TEXT,
    funcao_risco_id     INTEGER REFERENCES public.funcao_riscos(id),
    ativo               BOOLEAN DEFAULT TRUE,
    criado_em           TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    atualizado_em       TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_aet_metodologias_aet_id     ON public.aet_metodologias(aet_id);
CREATE INDEX IF NOT EXISTS idx_aet_metodologias_empresa_id  ON public.aet_metodologias(empresa_id);

-- RLS
ALTER TABLE public.aet_metodologias ENABLE ROW LEVEL SECURITY;

CREATE POLICY acesso_aet_metodologias ON public.aet_metodologias
    USING (empresa_id IN (
        SELECT empresa_id FROM public.empresas_do_usuario()
    ));

-- Sequence para serial (Supabase usa serial, não GENERATED ALWAYS)
CREATE SEQUENCE IF NOT EXISTS public.aet_metodologias_id_seq
    AS INTEGER START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
ALTER SEQUENCE public.aet_metodologias_id_seq OWNED BY public.aet_metodologias.id;


-- ── 2. COLUNAS EM aet_avaliacoes ─────────────────────────
ALTER TABLE public.aet_avaliacoes
    ADD COLUMN IF NOT EXISTS tipo_aet                       VARCHAR(30) DEFAULT 'Checklist NR-17',
    -- Checklist NR-17 | Metodologia Quantitativa | Completa
    ADD COLUMN IF NOT EXISTS nivel_risco_geral              VARCHAR(30),
    ADD COLUMN IF NOT EXISTS exposicao_habitual_permanente  BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS validade_meses                 INTEGER DEFAULT 12,
    ADD COLUMN IF NOT EXISTS unidade_id                     INTEGER REFERENCES public.unidades(id);


-- ── 3. COLUNAS EM funcao_riscos ──────────────────────────
ALTER TABLE public.funcao_riscos
    ADD COLUMN IF NOT EXISTS aet_id             INTEGER REFERENCES public.aet_avaliacoes(id),
    ADD COLUMN IF NOT EXISTS aet_metodologia_id INTEGER REFERENCES public.aet_metodologias(id),
    ADD COLUMN IF NOT EXISTS origem_aet         BOOLEAN DEFAULT FALSE;


-- ── 4. COLUNAS EM setor_riscos ───────────────────────────
ALTER TABLE public.setor_riscos
    ADD COLUMN IF NOT EXISTS aet_id             INTEGER REFERENCES public.aet_avaliacoes(id),
    ADD COLUMN IF NOT EXISTS aet_metodologia_id INTEGER REFERENCES public.aet_metodologias(id),
    ADD COLUMN IF NOT EXISTS origem_aet         BOOLEAN DEFAULT FALSE;


-- ── 5. GRANT (mesmos grants das tabelas aet existentes) ──
GRANT SELECT, INSERT, UPDATE, DELETE ON public.aet_metodologias TO authenticated;
GRANT USAGE ON SEQUENCE public.aet_metodologias_id_seq TO authenticated;
