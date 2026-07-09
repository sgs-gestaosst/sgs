-- Registro profissional do instrutor (por treinamento)
ALTER TABLE funcionarios_treinamentos ADD COLUMN IF NOT EXISTS registro_instrutor VARCHAR(80);

-- Registro profissional do responsável técnico (por empresa)
ALTER TABLE empresas ADD COLUMN IF NOT EXISTS registro_responsavel VARCHAR(80);
