-- ══════════════════════════════════════════════════════
-- SGS — EAD: permissões + colunas complementares
-- Rodar DEPOIS de ead_nr01_implementacao.sql
-- ══════════════════════════════════════════════════════

-- 1. Guardar nome, CPF e funcao_id do trabalhador no participante
--    (página pública não acessa tabela funcionarios por RLS)
ALTER TABLE turma_virtual_participantes
  ADD COLUMN IF NOT EXISTS nome_funcionario VARCHAR(150),
  ADD COLUMN IF NOT EXISTS cpf_funcionario  VARCHAR(20),
  ADD COLUMN IF NOT EXISTS funcao_id        INTEGER;

-- 2. Permitir que a página pública (anon) insira o registro de treinamento
--    após o trabalhador ser aprovado na prova
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='funcionario_treinamentos' AND policyname='ead_anon_insert_treinamento'
  ) THEN
    EXECUTE 'CREATE POLICY ead_anon_insert_treinamento ON funcionario_treinamentos FOR INSERT TO anon WITH CHECK (true)';
  END IF;
END $$;

-- 3. Permitir que a página pública insira os carimbos de aceite
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename='cert_assinaturas' AND policyname='ead_anon_insert_assinatura'
  ) THEN
    EXECUTE 'CREATE POLICY ead_anon_insert_assinatura ON cert_assinaturas FOR INSERT TO anon WITH CHECK (true)';
  END IF;
END $$;
