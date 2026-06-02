-- Módulo de Orçamentos — dados do elaborador (consultoria emissora)
-- Executar no Supabase SQL Editor

ALTER TABLE orcamentos
  ADD COLUMN IF NOT EXISTS elaborador_nome text,
  ADD COLUMN IF NOT EXISTS elaborador_cnpj text,
  ADD COLUMN IF NOT EXISTS elaborador_resp text,
  ADD COLUMN IF NOT EXISTS elaborador_reg  text;
