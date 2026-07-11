-- ══════════════════════════════════════════════════════
-- SGS — Módulo EAD: NR-01
-- Rodar no SQL Editor do Supabase
-- ══════════════════════════════════════════════════════


-- ── 1. COLUNAS NOVAS EM TABELAS EXISTENTES ────────────

ALTER TABLE catalogo_treinamentos
  ADD COLUMN IF NOT EXISTS exige_pratica BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS descricao_pratica TEXT;

ALTER TABLE funcionario_treinamentos
  ADD COLUMN IF NOT EXISTS modalidade VARCHAR(20) DEFAULT 'Presencial',
  ADD COLUMN IF NOT EXISTS data_teoria DATE,
  ADD COLUMN IF NOT EXISTS turma_virtual_id INTEGER;


-- ── 2. TABELA: conteúdo EAD (slides) ─────────────────

CREATE TABLE IF NOT EXISTS treinamentos_ead (
  id                SERIAL PRIMARY KEY,
  treinamento_id    INTEGER NOT NULL REFERENCES catalogo_treinamentos(id),
  slides            JSONB NOT NULL DEFAULT '[]',
  criado_em         TIMESTAMPTZ DEFAULT NOW(),
  ativo             BOOLEAN DEFAULT TRUE
);

ALTER TABLE treinamentos_ead ENABLE ROW LEVEL SECURITY;
CREATE POLICY ead_conteudo_publico ON treinamentos_ead FOR SELECT USING (true);


-- ── 3. TABELA: questões da prova ──────────────────────

CREATE TABLE IF NOT EXISTS questoes_ead (
  id                SERIAL PRIMARY KEY,
  treinamento_id    INTEGER NOT NULL REFERENCES catalogo_treinamentos(id),
  ordem             INTEGER NOT NULL,
  pergunta          TEXT NOT NULL,
  opcao_a           TEXT NOT NULL,
  opcao_b           TEXT NOT NULL,
  opcao_c           TEXT NOT NULL,
  opcao_d           TEXT NOT NULL,
  resposta_correta  CHAR(1) NOT NULL CHECK (resposta_correta IN ('a','b','c','d')),
  ativo             BOOLEAN DEFAULT TRUE
);

ALTER TABLE questoes_ead ENABLE ROW LEVEL SECURITY;
CREATE POLICY questoes_publico ON questoes_ead FOR SELECT USING (true);


-- ── 4. TABELA: turmas virtuais ────────────────────────

CREATE TABLE IF NOT EXISTS turmas_virtuais (
  id                    SERIAL PRIMARY KEY,
  empresa_id            INTEGER NOT NULL,
  treinamento_id        INTEGER NOT NULL REFERENCES catalogo_treinamentos(id),
  codigo_turma          VARCHAR(20) NOT NULL,
  instrutor             VARCHAR(150),
  registro_instrutor    VARCHAR(80),
  nome_responsavel      VARCHAR(150),
  registro_responsavel  VARCHAR(80),
  data_abertura         DATE NOT NULL DEFAULT CURRENT_DATE,
  data_validade         DATE,
  status                VARCHAR(20) DEFAULT 'ativa' CHECK (status IN ('ativa','encerrada')),
  criado_em             TIMESTAMPTZ DEFAULT NOW(),
  ativo                 BOOLEAN DEFAULT TRUE
);

ALTER TABLE turmas_virtuais ENABLE ROW LEVEL SECURITY;
CREATE POLICY tv_empresa ON turmas_virtuais USING (empresa_id = (
  SELECT (auth.jwt()->'user_metadata'->>'empresa_id')::int
));


-- ── 5. TABELA: participantes da turma virtual ─────────

CREATE TABLE IF NOT EXISTS turma_virtual_participantes (
  id                      SERIAL PRIMARY KEY,
  turma_virtual_id        INTEGER NOT NULL REFERENCES turmas_virtuais(id),
  funcionario_id          INTEGER NOT NULL,
  empresa_id              INTEGER NOT NULL,
  token_acesso            UUID DEFAULT gen_random_uuid() UNIQUE NOT NULL,
  status                  VARCHAR(30) DEFAULT 'pendente'
                            CHECK (status IN ('pendente','em_progresso','teoria_aprovada','aguardando_pratica','aprovado','reprovado')),
  slide_atual             INTEGER DEFAULT 0,
  nota_final              NUMERIC(5,2),
  tentativas              INTEGER DEFAULT 0,
  data_teoria_conclusao   TIMESTAMPTZ,
  data_conclusao          TIMESTAMPTZ,
  criado_em               TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE turma_virtual_participantes ENABLE ROW LEVEL SECURITY;

-- Admin acessa por empresa
CREATE POLICY tvp_empresa ON turma_virtual_participantes USING (empresa_id = (
  SELECT (auth.jwt()->'user_metadata'->>'empresa_id')::int
));

-- Participante acessa pelo token (público, sem auth)
CREATE POLICY tvp_token_publico ON turma_virtual_participantes
  FOR SELECT USING (true);

CREATE POLICY tvp_token_update ON turma_virtual_participantes
  FOR UPDATE USING (true);


-- ── 6. NR-01 no catálogo (inserir se não existir) ─────

INSERT INTO catalogo_treinamentos (nome, nr_relacionada, carga_horaria_inicial, carga_horaria_reciclagem, periodicidade_reciclagem, exige_pratica, ativo)
SELECT 'NR-01 Disposições Gerais de SST', 'NR-01', 8, 4, 'Bienal', false, true
WHERE NOT EXISTS (
  SELECT 1 FROM catalogo_treinamentos WHERE nr_relacionada = 'NR-01'
);


-- ── 7. SLIDES NR-01 ───────────────────────────────────

INSERT INTO treinamentos_ead (treinamento_id, slides)
SELECT
  (SELECT id FROM catalogo_treinamentos WHERE nr_relacionada = 'NR-01' LIMIT 1),
  '[
    {
      "ordem": 1,
      "icone": "📋",
      "titulo": "O que é a NR-01?",
      "texto": "A NR-01 é a Norma Regulamentadora número 1 do Ministério do Trabalho e Emprego. Ela estabelece as disposições gerais de Segurança e Saúde no Trabalho que se aplicam a todos os trabalhadores e empregadores do Brasil. A NR-01 foi atualizada em 2023 e passou a exigir o Gerenciamento de Riscos Ocupacionais nas empresas, tornando obrigatória a identificação e o controle de todos os riscos presentes no ambiente de trabalho."
    },
    {
      "ordem": 2,
      "icone": "✅",
      "titulo": "Seus Direitos como Trabalhador",
      "texto": "Você tem direito a: receber informações claras sobre todos os riscos do seu trabalho; ser consultado sobre as medidas de segurança adotadas; recusar trabalho em condições que representem risco grave e iminente à sua vida ou saúde; receber os Equipamentos de Proteção Individual (EPI) de forma totalmente gratuita; participar da CIPA e de programas de treinamento em segurança; e trabalhar em um ambiente seguro e com condições adequadas de saúde."
    },
    {
      "ordem": 3,
      "icone": "🤝",
      "titulo": "Suas Obrigações como Trabalhador",
      "texto": "Você tem o dever de: cumprir todas as normas de segurança e saúde no trabalho; usar corretamente os EPIs fornecidos pelo empregador; participar dos treinamentos de segurança sempre que convocado; comunicar ao seu supervisor qualquer situação de risco que identificar no ambiente de trabalho; colaborar com a empresa na aplicação das normas de segurança; e não danificar, remover ou inutilizar dispositivos de proteção coletiva instalados."
    },
    {
      "ordem": 4,
      "icone": "🏭",
      "titulo": "Obrigações do Empregador",
      "texto": "A empresa é obrigada a: garantir um ambiente de trabalho seguro e saudável; identificar, avaliar e controlar todos os riscos ocupacionais; fornecer EPIs gratuitamente e em perfeito estado de conservação; realizar treinamentos periódicos de segurança para todos os trabalhadores; manter o PGR (Programa de Gerenciamento de Riscos) e o PCMSO (Programa de Controle Médico de Saúde Ocupacional) atualizados; e comunicar os acidentes de trabalho ao INSS por meio da CAT."
    },
    {
      "ordem": 5,
      "icone": "⚠️",
      "titulo": "Tipos de Riscos Ocupacionais",
      "texto": "Os riscos no trabalho são classificados em 5 grupos: FÍSICOS — ruído, calor, frio, vibração, radiação; QUÍMICOS — poeiras, fumos, vapores e gases tóxicos; BIOLÓGICOS — vírus, bactérias, fungos e parasitas; ERGONÔMICOS — postura inadequada, esforço repetitivo, levantamento de peso, trabalho noturno; DE ACIDENTES — máquinas sem proteção, trabalho em altura, eletricidade, espaços confinados. Conhecer esses grupos ajuda você a identificar os riscos do seu dia a dia."
    },
    {
      "ordem": 6,
      "icone": "🔍",
      "titulo": "Como Identificar Riscos no Trabalho",
      "texto": "Fique atento no seu posto de trabalho: observe as máquinas e equipamentos — eles possuem proteções adequadas?; identifique substâncias químicas — estão rotuladas e armazenadas corretamente?; avalie sua postura — você trabalha em posição forçada por muito tempo?; verifique o ambiente — há ruído excessivo, calor intenso, pouca iluminação ou falta de ventilação?; perceba sinais do seu corpo — dores, cansaço fora do normal ou dificuldade para respirar podem ser sinais de risco. Comunique imediatamente ao supervisor qualquer risco identificado."
    },
    {
      "ordem": 7,
      "icone": "🚑",
      "titulo": "Acidente de Trabalho",
      "texto": "Acidente de trabalho é todo evento que ocorre pelo exercício do trabalho e provoca lesão corporal, perturbação funcional ou doença que cause morte, perda ou redução da capacidade para o trabalho. O QUE FAZER em caso de acidente: informe imediatamente o supervisor; procure atendimento médico sem demora; a empresa deve emitir a CAT até o 1º dia útil seguinte ao acidente; guarde toda documentação médica. Doenças causadas pelo trabalho — como LER, perda auditiva e problemas respiratórios — também são consideradas acidentes de trabalho."
    },
    {
      "ordem": 8,
      "icone": "📄",
      "titulo": "CAT — Comunicação de Acidente de Trabalho",
      "texto": "A CAT é um documento obrigatório que a empresa deve emitir ao INSS sempre que ocorre um acidente de trabalho ou doença ocupacional. A empresa tem até o 1º dia útil após o acidente para emitir a CAT. Se a empresa não emitir, o próprio trabalhador, o médico, o sindicato ou um familiar podem fazer a comunicação diretamente ao INSS. A CAT é fundamental para garantir ao trabalhador o acesso aos benefícios previdenciários como auxílio-doença acidentário e, em casos graves, aposentadoria por invalidez."
    },
    {
      "ordem": 9,
      "icone": "👥",
      "titulo": "SESMT e CIPA",
      "texto": "SESMT (Serviço Especializado em Engenharia de Segurança e Medicina do Trabalho): equipe interna de profissionais — engenheiros de segurança, médicos do trabalho, técnicos de segurança — que trabalha para prevenir acidentes e proteger a saúde dos trabalhadores. CIPA (Comissão Interna de Prevenção de Acidentes): grupo formado por representantes eleitos pelos empregados e indicados pela empresa, que identifica riscos, propõe melhorias nas condições de trabalho e promove a cultura de segurança. A participação na CIPA é garantida por lei e o cipeiro eleito tem estabilidade no emprego."
    },
    {
      "ordem": 10,
      "icone": "🛑",
      "titulo": "Direito de Recusa e Situações de Emergência",
      "texto": "Você tem o DIREITO GARANTIDO POR LEI de interromper suas atividades e se afastar do local quando houver risco grave e iminente à sua vida ou saúde. Exemplos: estrutura prestes a desabar; vazamento de gás ou produto químico perigoso; equipamento com defeito grave; ausência de EPI em atividade de alto risco. O QUE FAZER: comunique o supervisor antes de interromper; registre a ocorrência; nunca coloque sua vida em risco por pressão do trabalho. Em caso de emergência: acione o SAMU (192), Bombeiros (193) ou Defesa Civil (199). Lembre-se: nenhum trabalho vale mais do que sua vida."
    }
  ]'::jsonb
WHERE NOT EXISTS (
  SELECT 1 FROM treinamentos_ead WHERE treinamento_id = (
    SELECT id FROM catalogo_treinamentos WHERE nr_relacionada = 'NR-01' LIMIT 1
  )
);


-- ── 8. QUESTÕES DA PROVA NR-01 ────────────────────────

DO $$
DECLARE v_tid INTEGER;
BEGIN
  SELECT id INTO v_tid FROM catalogo_treinamentos WHERE nr_relacionada = 'NR-01' LIMIT 1;
  IF NOT EXISTS (SELECT 1 FROM questoes_ead WHERE treinamento_id = v_tid) THEN

    INSERT INTO questoes_ead (treinamento_id, ordem, pergunta, opcao_a, opcao_b, opcao_c, opcao_d, resposta_correta) VALUES

    (v_tid, 1,
     'Sobre o que trata a NR-01?',
     'Apenas sobre o uso de Equipamentos de Proteção Individual',
     'Disposições gerais de Segurança e Saúde no Trabalho aplicáveis a todos os trabalhadores',
     'Somente sobre acidentes de trabalho e suas consequências',
     'Regras exclusivas para empresas com mais de 100 funcionários',
     'b'),

    (v_tid, 2,
     'Qual é o prazo para a empresa emitir a CAT após um acidente de trabalho?',
     'Até 7 dias úteis após o acidente',
     'Até 30 dias corridos',
     'Até o 1º dia útil seguinte ao acidente',
     'Não há prazo obrigatório',
     'c'),

    (v_tid, 3,
     'Em qual situação o trabalhador tem o DIREITO de recusar a realização de uma tarefa?',
     'Quando considera o trabalho muito cansativo',
     'Quando há risco grave e iminente à sua vida ou saúde',
     'Quando não recebeu horas extras no mês anterior',
     'Quando a tarefa não faz parte do seu cargo original',
     'b'),

    (v_tid, 4,
     'Qual destes é um exemplo de risco QUÍMICO no trabalho?',
     'Ruído acima de 85 dB produzido por máquinas',
     'Trabalho em plataforma elevada sem proteção',
     'Exposição a vapores e gases tóxicos durante a jornada',
     'Postura inadequada por longo período',
     'c'),

    (v_tid, 5,
     'De que forma o empregador deve fornecer o EPI ao trabalhador?',
     'Pago, com desconto parcelado no salário',
     'Gratuito, sempre que solicitado pelo trabalhador',
     'Gratuito, como obrigação legal independente de solicitação',
     'Opcional, apenas para atividades consideradas de alto risco',
     'c'),

    (v_tid, 6,
     'A CIPA é composta por:',
     'Apenas representantes indicados pela empresa',
     'Apenas representantes eleitos pelos trabalhadores',
     'Representantes dos empregados eleitos e representantes indicados pela empresa',
     'Somente profissionais de medicina e engenharia do trabalho',
     'c'),

    (v_tid, 7,
     'Qual destes é um exemplo de risco ERGONÔMICO?',
     'Exposição a bactérias no ambiente de trabalho',
     'Esforço físico repetitivo e postura inadequada por longos períodos',
     'Contato com produtos inflamáveis',
     'Ruído excessivo causado por equipamentos',
     'b'),

    (v_tid, 8,
     'Se a empresa não emitir a CAT, quem pode fazê-la?',
     'Apenas a empresa empregadora tem essa obrigação, ninguém mais pode emitir',
     'Somente o médico do trabalho da empresa',
     'O próprio trabalhador, o médico, o sindicato ou um familiar',
     'Apenas o INSS, mediante requerimento formal',
     'c'),

    (v_tid, 9,
     'Qual é a principal função do SESMT dentro de uma empresa?',
     'Fiscalizar o cumprimento de horários e a produtividade dos funcionários',
     'Prevenir acidentes e proteger a saúde dos trabalhadores',
     'Representar os trabalhadores em negociações salariais e benefícios',
     'Emitir certificados e registrar treinamentos realizados',
     'b'),

    (v_tid, 10,
     'Ao identificar uma situação de risco no seu local de trabalho, o que você deve fazer?',
     'Ignorar e continuar trabalhando, pois a empresa é responsável por isso',
     'Resolver o problema sozinho, sem informar ninguém para não gerar conflito',
     'Comunicar imediatamente ao supervisor e, se necessário, interromper a atividade',
     'Aguardar o próximo treinamento de segurança para relatar formalmente',
     'c');

  END IF;
END $$;
