-- Migration: ASO — adequação NR-07 7.5.19.1 e 7.5.19.2
-- Adiciona colunas para CNPJ da empresa e aptidão para atividades específicas
-- As colunas crm_coordenador e uf_crm_coordenador já existem no schema

ALTER TABLE esocial_s2220
  ADD COLUMN IF NOT EXISTS cnpj_empresa varchar(18),
  ADD COLUMN IF NOT EXISTS aptidao_atividades_especificas text;
