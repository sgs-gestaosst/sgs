-- ═══════════════════════════════════════════════════════════════════
-- ACEITES DIGITAIS DE CERTIFICADOS — cert_assinaturas
-- Executar no Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS public.cert_assinaturas (
  id                          SERIAL PRIMARY KEY,
  funcionario_treinamento_id  INTEGER NOT NULL,
  empresa_id                  INTEGER NOT NULL,
  tipo                        VARCHAR(30) NOT NULL
    CHECK (tipo IN ('funcionario','instrutor','responsavel_tecnico')),
  nome_signatario             VARCHAR(200) NOT NULL,
  cargo_signatario            VARCHAR(200),
  token                       UUID DEFAULT gen_random_uuid() NOT NULL,
  token_expira_em             TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '30 days'),
  status                      VARCHAR(20) DEFAULT 'pendente'
    CHECK (status IN ('pendente','aceito')),
  aceito_em                   TIMESTAMPTZ,
  criado_em                   TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT cert_ass_token_uniq UNIQUE (token),
  CONSTRAINT cert_ass_reg_tipo_uniq UNIQUE (funcionario_treinamento_id, tipo)
);

ALTER TABLE cert_assinaturas ENABLE ROW LEVEL SECURITY;

-- Usuários autenticados: acesso total (isolamento por empresa_id é
-- garantido na criação — o app só cria registros da empresa do usuário)
CREATE POLICY "cert_ass_auth" ON cert_assinaturas
FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Anon: pode ler para verificar o token na página assinar.html
CREATE POLICY "cert_ass_anon_select" ON cert_assinaturas
FOR SELECT TO anon USING (true);

-- Anon: pode aceitar — só funciona em tokens pendentes
CREATE POLICY "cert_ass_anon_update" ON cert_assinaturas
FOR UPDATE TO anon
USING  (status = 'pendente')
WITH CHECK (status = 'aceito');

-- ───────────────────────────────────────────────────────────────────
-- Índice para busca por token (página pública)
CREATE INDEX IF NOT EXISTS idx_cert_ass_token ON cert_assinaturas (token);
-- Índice para busca por registro (modal de assinaturas)
CREATE INDEX IF NOT EXISTS idx_cert_ass_reg ON cert_assinaturas (funcionario_treinamento_id);
-- ═══════════════════════════════════════════════════════════════════
