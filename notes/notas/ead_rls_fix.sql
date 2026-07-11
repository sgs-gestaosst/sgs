-- Fix RLS turmas_virtuais e turma_virtual_participantes
-- Substituir políticas por: authenticated faz tudo, anon só lê/atualiza pelo token

-- turmas_virtuais
DROP POLICY IF EXISTS tv_empresa ON turmas_virtuais;
CREATE POLICY tv_auth ON turmas_virtuais
  FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- turma_virtual_participantes (admin)
DROP POLICY IF EXISTS tvp_empresa ON turma_virtual_participantes;
CREATE POLICY tvp_auth ON turma_virtual_participantes
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
