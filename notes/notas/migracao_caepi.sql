-- ============================================================
-- Migração: Base CAEPI — Certificados de Aprovação de EPI
-- Executar no Supabase SQL Editor (uma vez)
-- ============================================================

-- Tabela principal
CREATE TABLE IF NOT EXISTS public.ca_epi (
  numero_ca              TEXT PRIMARY KEY,
  nome_equipamento       TEXT,
  descricao_equipamento  TEXT,
  marca                  TEXT,
  referencia             TEXT,
  data_validade          TEXT,
  situacao               TEXT,
  norma                  TEXT,
  cnpj_fabricante        TEXT,
  razao_social_fabricante TEXT,
  atualizado_em          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ca_epi_situacao ON public.ca_epi(situacao);

-- Log de importações
CREATE TABLE IF NOT EXISTS public.ca_epi_importacoes (
  id              SERIAL PRIMARY KEY,
  executado_em    TIMESTAMP DEFAULT NOW(),
  total_registros INTEGER,
  sucesso         BOOLEAN,
  erro            TEXT
);

-- RLS: qualquer usuário autenticado pode ler, só service_role pode escrever
ALTER TABLE public.ca_epi ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ca_epi_importacoes ENABLE ROW LEVEL SECURITY;

CREATE POLICY ca_epi_leitura ON public.ca_epi
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY ca_epi_importacoes_leitura ON public.ca_epi_importacoes
  FOR SELECT USING (auth.uid() IS NOT NULL);

-- Verificação
SELECT 'Tabelas ca_epi e ca_epi_importacoes criadas com sucesso.' AS resultado;
