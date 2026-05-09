-- ============================================================
-- Migração: campo epi_nome nas tabelas de medidas
-- Permite armazenar nome do EPI da base CAEPI sem depender do catalogo_epis
-- ============================================================

ALTER TABLE public.setor_risco_medidas
  ADD COLUMN IF NOT EXISTS epi_nome TEXT;

ALTER TABLE public.funcao_risco_medidas
  ADD COLUMN IF NOT EXISTS epi_nome TEXT;

SELECT 'Colunas epi_nome adicionadas com sucesso.' AS resultado;
