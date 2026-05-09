-- ============================================================
-- Migração v3 — Novo modelo de planos SGS
-- Executar no Supabase SQL Editor (uma vez)
-- ============================================================

-- ── 1. Adicionar colunas à tabela planos ──────────────────
ALTER TABLE public.planos
  ADD COLUMN IF NOT EXISTS limite_empresas INTEGER NOT NULL DEFAULT 9999,
  ADD COLUMN IF NOT EXISTS tem_esocial BOOLEAN NOT NULL DEFAULT true;

-- ── 2. Desativar planos antigos ───────────────────────────
UPDATE public.planos SET ativo = false;

-- ── 3. Inserir os 5 novos planos ──────────────────────────
INSERT INTO public.planos
  (nome, descricao, limite_empresas, limite_funcionarios, numero_usuarios, valor_mensal, tem_esocial, gera_pgr, gera_pcmso, gera_ltcat, checklist_mobile, suporte, ativo)
VALUES
  ('Free',       'Plano gratuito para avaliação do sistema',           2,    25,    1,      0.00, false, true, true, true, true, 'Email',    true),
  ('Starter',    'Para técnicos solo e pequenas consultorias',         8,   120,    2,     79.00, true,  true, true, true, true, 'Email',    true),
  ('Pro',        'Para consultorias em crescimento',                  15,   300,    3,    279.00, true,  true, true, true, true, 'Chat',     true),
  ('Business',   'Para consultorias médias e SESMTs corporativos',    60,  1500, 9999,   549.00, true,  true, true, true, true, 'WhatsApp', true),
  ('Enterprise', 'Operações ilimitadas — grandes consultorias',     9999, 99999, 9999,  949.00, true,  true, true, true, true, 'Dedicado', true);

-- ── 4. Atualizar constraint de status em assinaturas ──────
ALTER TABLE public.assinaturas
  DROP CONSTRAINT IF EXISTS assinaturas_status_check;

ALTER TABLE public.assinaturas
  ADD CONSTRAINT assinaturas_status_check CHECK (
    status IN ('Free', 'Ativo', 'Suspenso', 'Cancelado', 'Trial', 'Enterprise')
  );

-- ── 5. Migrar assinaturas Trial existentes → Free ─────────
-- Assinaturas Trial com vencimento no futuro → Ativo no plano Starter (benefício da migração)
-- Assinaturas Trial vencidas ou sem registro → Free
UPDATE public.assinaturas
SET
  status   = 'Ativo',
  plano_id = (SELECT id FROM public.planos WHERE nome = 'Starter' AND ativo = true LIMIT 1)
WHERE status = 'Trial'
  AND (data_fim_trial IS NULL OR data_fim_trial >= CURRENT_DATE);

UPDATE public.assinaturas
SET
  status   = 'Free',
  plano_id = (SELECT id FROM public.planos WHERE nome = 'Free' AND ativo = true LIMIT 1)
WHERE status = 'Trial'
  AND data_fim_trial < CURRENT_DATE;

-- ── 6. Backfill: usuários sem assinatura → Free ───────────
INSERT INTO public.assinaturas (user_id, plano_id, status, data_inicio, ativo)
SELECT
  u.id,
  (SELECT id FROM public.planos WHERE nome = 'Free' AND ativo = true LIMIT 1),
  'Free',
  CURRENT_DATE,
  true
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM public.assinaturas a
  WHERE a.user_id = u.id AND a.ativo = true
);

-- ── 7. Corrigir trigger trg_novo_usuario ──────────────────
-- Antes: disparava só em UPDATE (email confirmado), criava Trial
-- Agora: dispara em INSERT ou UPDATE, cria plano Free permanente

CREATE OR REPLACE FUNCTION public.trg_fn_novo_usuario()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Só processa quando e-mail estiver confirmado
  -- Em INSERT: email_confirmed_at já preenchido (criado via dashboard)
  -- Em UPDATE: mudança de NULL → valor (fluxo normal de confirmação)
  IF NEW.email_confirmed_at IS NOT NULL AND (
    TG_OP = 'INSERT' OR OLD.email_confirmed_at IS NULL
  ) THEN

    -- Inserir na tabela usuarios como ADMIN (se ainda não existir)
    INSERT INTO public.usuarios (user_id, nome_completo, email, perfil, ativo)
    VALUES (
      NEW.id,
      COALESCE(NEW.raw_user_meta_data->>'nome_completo', split_part(NEW.email, '@', 1)),
      NEW.email,
      'ADMIN',
      true
    )
    ON CONFLICT (user_id) DO NOTHING;

    -- Criar assinatura no plano Free (se ainda não existir)
    INSERT INTO public.assinaturas (user_id, plano_id, status, data_inicio, valor_base, ativo)
    SELECT
      NEW.id,
      p.id,
      'Free',
      CURRENT_DATE,
      0.00,
      true
    FROM public.planos p
    WHERE p.nome = 'Free' AND p.ativo = true
    AND NOT EXISTS (
      SELECT 1 FROM public.assinaturas
      WHERE user_id = NEW.id AND ativo = true
    )
    LIMIT 1;

  END IF;
  RETURN NEW;
END;
$$;

-- Recriar o trigger para disparar em INSERT e UPDATE
DROP TRIGGER IF EXISTS trg_novo_usuario ON auth.users;

CREATE TRIGGER trg_novo_usuario
  AFTER INSERT OR UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_fn_novo_usuario();

-- ── 8. SUPERADMIN: sgs.gestaosst@gmail.com ───────────────
INSERT INTO public.usuarios (user_id, nome_completo, email, perfil, ativo)
SELECT
  id,
  'SGS Admin',
  'sgs.gestaosst@gmail.com',
  'SUPERADMIN',
  true
FROM auth.users
WHERE email = 'sgs.gestaosst@gmail.com'
ON CONFLICT (user_id) DO UPDATE SET perfil = 'SUPERADMIN', ativo = true;

-- ── Verificação final ─────────────────────────────────────
SELECT nome, limite_empresas, limite_funcionarios, numero_usuarios, valor_mensal, tem_esocial, suporte
FROM public.planos
WHERE ativo = true
ORDER BY valor_mensal;
