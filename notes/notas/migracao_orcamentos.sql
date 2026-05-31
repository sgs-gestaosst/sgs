-- ============================================================
-- MÓDULO DE ORÇAMENTOS — Migration
-- Executar no Supabase SQL Editor
-- ============================================================

-- 1. CATÁLOGO DE SERVIÇOS (por empresa/consultoria)
CREATE TABLE IF NOT EXISTS orcamento_catalogo (
  id            uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  empresa_id    integer NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  categoria     text NOT NULL,
  nome          text NOT NULL,
  descricao     text,
  unidade       text NOT NULL DEFAULT 'unidade',
  tipo          text NOT NULL DEFAULT 'servico',
  preco_padrao  numeric(10,2) NOT NULL DEFAULT 0,
  percentual    numeric(5,4),
  precos_json   jsonb,
  recorrencia   text NOT NULL DEFAULT 'unica',
  ativo         boolean NOT NULL DEFAULT true,
  ordem         integer NOT NULL DEFAULT 0,
  criado_em     timestamptz DEFAULT now(),
  atualizado_em timestamptz DEFAULT now()
);

ALTER TABLE orcamento_catalogo ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "catalogo_empresa" ON orcamento_catalogo;
CREATE POLICY "catalogo_empresa" ON orcamento_catalogo
  FOR ALL USING (
    empresa_id IN (
      SELECT empresa_id FROM usuarios WHERE user_id = auth.uid()
      UNION SELECT id FROM empresas WHERE id = empresa_id AND '{"role":"superadmin"}' @> (
        SELECT raw_app_meta_data FROM auth.users WHERE id = auth.uid()
      )
    )
  );

-- 2. ORÇAMENTOS (cabeçalho)
CREATE TABLE IF NOT EXISTS orcamentos (
  id                       uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  empresa_id               integer NOT NULL REFERENCES empresas(id) ON DELETE CASCADE,
  numero                   text NOT NULL DEFAULT '',
  cliente_nome             text NOT NULL,
  cliente_cnpj             text,
  cliente_cnae             text,
  cliente_municipio        text,
  num_funcionarios         integer NOT NULL DEFAULT 0,
  num_cargos               integer NOT NULL DEFAULT 0,
  num_estabelecimentos     integer NOT NULL DEFAULT 1,
  grau_risco               text NOT NULL DEFAULT 'GR1',
  urgencia                 text DEFAULT 'Normal (30 dias)',
  motivo                   text,
  tem_documentacao_anterior boolean DEFAULT false,
  pct_impostos             numeric(5,4) NOT NULL DEFAULT 0.12,
  pct_margem               numeric(5,4) NOT NULL DEFAULT 0.30,
  custo_deslocamento       numeric(10,2) NOT NULL DEFAULT 150,
  custo_software           numeric(10,2) NOT NULL DEFAULT 80,
  valor_base               numeric(10,2) DEFAULT 0,
  valor_ajustes            numeric(10,2) DEFAULT 0,
  valor_custos_op          numeric(10,2) DEFAULT 0,
  valor_impostos           numeric(10,2) DEFAULT 0,
  valor_margem             numeric(10,2) DEFAULT 0,
  valor_total              numeric(10,2) DEFAULT 0,
  valor_unico              numeric(10,2) DEFAULT 0,
  valor_mensal             numeric(10,2) DEFAULT 0,
  valor_anual              numeric(10,2) DEFAULT 0,
  status                   text NOT NULL DEFAULT 'rascunho',
  validade_dias            integer NOT NULL DEFAULT 15,
  observacoes              text,
  contrato_texto           text,
  contrato_gerado_em       timestamptz,
  ativo                    boolean NOT NULL DEFAULT true,
  criado_em                timestamptz DEFAULT now(),
  atualizado_em            timestamptz DEFAULT now()
);

ALTER TABLE orcamentos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "orcamentos_empresa" ON orcamentos;
CREATE POLICY "orcamentos_empresa" ON orcamentos
  FOR ALL USING (
    empresa_id IN (
      SELECT empresa_id FROM usuarios WHERE user_id = auth.uid()
    )
  );

-- 3. ITENS DO ORÇAMENTO
CREATE TABLE IF NOT EXISTS orcamento_itens (
  id             uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  orcamento_id   uuid NOT NULL REFERENCES orcamentos(id) ON DELETE CASCADE,
  catalogo_id    uuid REFERENCES orcamento_catalogo(id) ON DELETE SET NULL,
  servico_nome   text NOT NULL,
  unidade        text NOT NULL DEFAULT 'unidade',
  tipo           text NOT NULL DEFAULT 'servico',
  recorrencia    text NOT NULL DEFAULT 'unica',
  incluso        boolean NOT NULL DEFAULT true,
  quantidade     numeric(10,2) NOT NULL DEFAULT 1,
  preco_unitario numeric(10,2) NOT NULL DEFAULT 0,
  subtotal       numeric(10,2) NOT NULL DEFAULT 0,
  ordem          integer NOT NULL DEFAULT 0
);

ALTER TABLE orcamento_itens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "itens_via_orcamento" ON orcamento_itens;
CREATE POLICY "itens_via_orcamento" ON orcamento_itens
  FOR ALL USING (
    orcamento_id IN (
      SELECT id FROM orcamentos WHERE empresa_id IN (
        SELECT empresa_id FROM usuarios WHERE user_id = auth.uid()
      )
    )
  );

-- 4. SEQUENCE + TRIGGER para numeração automática
CREATE SEQUENCE IF NOT EXISTS orcamento_seq START 1;

CREATE OR REPLACE FUNCTION gerar_numero_orcamento()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.numero IS NULL OR NEW.numero = '' THEN
    NEW.numero := 'ORC-' || to_char(now(), 'YYYY') || '-'
                  || lpad(nextval('orcamento_seq')::text, 3, '0');
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_numero_orcamento ON orcamentos;
CREATE TRIGGER trg_numero_orcamento
  BEFORE INSERT ON orcamentos
  FOR EACH ROW
  EXECUTE FUNCTION gerar_numero_orcamento();
