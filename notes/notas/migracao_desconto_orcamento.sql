-- Módulo de Orçamentos — adicionar desconto
-- Executar no Supabase SQL Editor

ALTER TABLE orcamentos
  ADD COLUMN IF NOT EXISTS desconto_tipo  text    NOT NULL DEFAULT 'nenhum',
  ADD COLUMN IF NOT EXISTS desconto_valor numeric(10,2) NOT NULL DEFAULT 0;

-- desconto_tipo: 'nenhum' | 'percentual' | 'fixo'
-- desconto_valor: percentual (0.10 = 10%) ou valor fixo em R$
