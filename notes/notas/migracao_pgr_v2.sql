-- ============================================================
-- Migração PGR v2 — Contratadas, Participação, Versões, Indicador
-- Executar no Supabase SQL Editor (uma vez)
-- ============================================================

-- ── 1. Empresas contratadas ───────────────────────────────────
CREATE TABLE IF NOT EXISTS public.empresa_contratadas (
  id                  SERIAL PRIMARY KEY,
  empresa_id          INTEGER NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  razao_social        VARCHAR(200) NOT NULL,
  cnpj                VARCHAR(20),
  servico_prestado    TEXT NOT NULL,
  frequencia          VARCHAR(20) CHECK (frequencia IN ('Diária','Semanal','Mensal','Eventual')),
  riscos_categorias   TEXT,
  setores_atuacao     TEXT,
  medidas_acordadas   TEXT,
  ativo               BOOLEAN DEFAULT true,
  criado_em           TIMESTAMP DEFAULT NOW(),
  atualizado_em       TIMESTAMP DEFAULT NOW()
);

ALTER TABLE public.empresa_contratadas ENABLE ROW LEVEL SECURITY;
CREATE POLICY contratadas_select ON public.empresa_contratadas FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY contratadas_insert ON public.empresa_contratadas FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY contratadas_update ON public.empresa_contratadas FOR UPDATE USING (auth.uid() IS NOT NULL);
CREATE POLICY contratadas_delete ON public.empresa_contratadas FOR DELETE USING (auth.uid() IS NOT NULL);

-- ── 2. Participação dos trabalhadores no PGR ──────────────────
CREATE TABLE IF NOT EXISTS public.pgr_participacao (
  id                      SERIAL PRIMARY KEY,
  empresa_id              INTEGER NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  data_divulgacao         DATE,
  forma_divulgacao        TEXT,
  responsavel_comunicacao VARCHAR(200),
  mecanismo_consulta      TEXT,
  canal_comunicacao       TEXT,
  observacoes             TEXT,
  atualizado_em           TIMESTAMP DEFAULT NOW(),
  UNIQUE(empresa_id)
);

ALTER TABLE public.pgr_participacao ENABLE ROW LEVEL SECURITY;
CREATE POLICY participacao_all ON public.pgr_participacao FOR ALL USING (auth.uid() IS NOT NULL);

-- ── 3. Controle de versões do PGR ────────────────────────────
CREATE TABLE IF NOT EXISTS public.pgr_versoes (
  id                  SERIAL PRIMARY KEY,
  empresa_id          INTEGER NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
  versao              VARCHAR(20) NOT NULL DEFAULT '1.0',
  data_revisao        DATE NOT NULL DEFAULT CURRENT_DATE,
  autor               VARCHAR(200),
  descricao_alteracao TEXT,
  criado_em           TIMESTAMP DEFAULT NOW()
);

ALTER TABLE public.pgr_versoes ENABLE ROW LEVEL SECURITY;
CREATE POLICY versoes_all ON public.pgr_versoes FOR ALL USING (auth.uid() IS NOT NULL);

-- Insere versão inicial para empresas que já existem
INSERT INTO public.pgr_versoes (empresa_id, versao, data_revisao, descricao_alteracao)
SELECT id, '1.0', CURRENT_DATE, 'Versão inicial'
FROM public.empresas
WHERE ativo = true
ON CONFLICT DO NOTHING;

-- ── 4. Indicador/meta nas ações ───────────────────────────────
ALTER TABLE public.acoes
  ADD COLUMN IF NOT EXISTS indicador TEXT;

-- ── Verificação ───────────────────────────────────────────────
SELECT 'Tabelas empresa_contratadas, pgr_participacao, pgr_versoes criadas. Coluna indicador adicionada em acoes.' AS resultado;
