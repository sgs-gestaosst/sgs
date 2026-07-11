-- ══════════════════════════════════════════════════════
-- SGS — EAD NR-01: slides com layout visual (itens + cards)
-- Rodar no SQL Editor do Supabase
-- ══════════════════════════════════════════════════════

UPDATE treinamentos_ead
SET slides = '[
  {
    "ordem": 1,
    "icone": "📋",
    "titulo": "O que é a NR-01?",
    "texto": "A NR-01 é a Norma Regulamentadora número 1 do Ministério do Trabalho e Emprego. Ela estabelece as disposições gerais de Segurança e Saúde no Trabalho que se aplicam a todos os trabalhadores e empregadores do Brasil.",
    "destaque": "Desde 2023, a NR-01 exige o Gerenciamento de Riscos Ocupacionais (GRO) em todas as empresas."
  },
  {
    "ordem": 2,
    "icone": "✅",
    "titulo": "Seus Direitos como Trabalhador",
    "texto": "A lei garante a você:",
    "items": [
      {"icone": "📢", "texto": "Receber informações claras sobre todos os riscos do seu trabalho"},
      {"icone": "💬", "texto": "Ser consultado sobre as medidas de segurança adotadas"},
      {"icone": "🛑", "texto": "Recusar trabalho com risco grave e iminente à sua vida"},
      {"icone": "🦺", "texto": "Receber EPI gratuitamente e em perfeito estado"},
      {"icone": "👥", "texto": "Participar da CIPA e de treinamentos de segurança"}
    ]
  },
  {
    "ordem": 3,
    "icone": "🤝",
    "titulo": "Suas Obrigações como Trabalhador",
    "texto": "Você tem o dever de:",
    "items": [
      {"icone": "📜", "texto": "Cumprir todas as normas de segurança e saúde no trabalho"},
      {"icone": "🦺", "texto": "Usar corretamente os EPIs fornecidos pelo empregador"},
      {"icone": "🎓", "texto": "Participar dos treinamentos de segurança sempre que convocado"},
      {"icone": "📣", "texto": "Comunicar ao supervisor qualquer risco identificado"},
      {"icone": "🔒", "texto": "Não remover ou inutilizar dispositivos de proteção"}
    ]
  },
  {
    "ordem": 4,
    "icone": "🏭",
    "titulo": "Obrigações do Empregador",
    "texto": "A empresa é obrigada a:",
    "items": [
      {"icone": "🛡️", "texto": "Garantir ambiente de trabalho seguro e saudável"},
      {"icone": "🔍", "texto": "Identificar, avaliar e controlar todos os riscos ocupacionais"},
      {"icone": "🦺", "texto": "Fornecer EPIs gratuitamente e em perfeito estado"},
      {"icone": "🎓", "texto": "Realizar treinamentos periódicos de segurança"},
      {"icone": "📋", "texto": "Manter PGR e PCMSO atualizados"},
      {"icone": "📄", "texto": "Emitir a CAT em caso de acidente de trabalho"}
    ]
  },
  {
    "ordem": 5,
    "icone": "⚠️",
    "titulo": "Tipos de Riscos Ocupacionais",
    "texto": "Os riscos no trabalho são classificados em 5 grupos:",
    "items": [
      {"icone": "🔊", "titulo": "FÍSICOS", "texto": "Ruído, calor, frio, vibração, radiação", "cor": "#FEF3C7"},
      {"icone": "☣️", "titulo": "QUÍMICOS", "texto": "Poeiras, fumos, vapores, gases tóxicos", "cor": "#FEE2E2"},
      {"icone": "🦠", "titulo": "BIOLÓGICOS", "texto": "Vírus, bactérias, fungos, parasitas", "cor": "#DCFCE7"},
      {"icone": "🪑", "titulo": "ERGONÔMICOS", "texto": "Postura inadequada, esforço repetitivo", "cor": "#EDE9FE"},
      {"icone": "⚡", "titulo": "DE ACIDENTES", "texto": "Máquinas sem proteção, trabalho em altura", "cor": "#FFF7ED"}
    ]
  },
  {
    "ordem": 6,
    "icone": "🔍",
    "titulo": "Como Identificar Riscos no Trabalho",
    "texto": "Fique atento no seu posto de trabalho:",
    "items": [
      {"icone": "🔧", "texto": "Máquinas e equipamentos — possuem proteções adequadas?"},
      {"icone": "🧪", "texto": "Substâncias químicas — estão rotuladas e armazenadas corretamente?"},
      {"icone": "💺", "texto": "Sua postura — você trabalha em posição forçada por muito tempo?"},
      {"icone": "🌡️", "texto": "Ambiente — há ruído, calor intenso ou falta de ventilação?"},
      {"icone": "💪", "texto": "Sinais do corpo — dores ou cansaço fora do normal?"},
      {"icone": "📢", "texto": "Comunique ao supervisor qualquer risco identificado!"}
    ]
  },
  {
    "ordem": 7,
    "icone": "🚑",
    "titulo": "Acidente de Trabalho",
    "texto": "Acidente de trabalho é todo evento que ocorre pelo exercício do trabalho e provoca lesão, doença ou morte. Doenças como LER e perda auditiva também são consideradas acidentes de trabalho.",
    "label_items": "O que fazer em caso de acidente:",
    "items": [
      {"icone": "1️⃣", "texto": "Informe imediatamente o supervisor"},
      {"icone": "2️⃣", "texto": "Procure atendimento médico sem demora"},
      {"icone": "3️⃣", "texto": "A empresa deve emitir a CAT até o 1º dia útil seguinte"},
      {"icone": "4️⃣", "texto": "Guarde toda documentação médica"}
    ]
  },
  {
    "ordem": 8,
    "icone": "📄",
    "titulo": "CAT — Comunicação de Acidente de Trabalho",
    "texto": "A CAT é um documento obrigatório que a empresa deve emitir ao INSS após um acidente ou doença ocupacional.",
    "destaque": "Prazo: até o 1º dia útil após o acidente.",
    "items": [
      {"icone": "👷", "texto": "Se a empresa não emitir, o próprio trabalhador pode fazê-la"},
      {"icone": "👨‍⚕️", "texto": "O médico também pode emitir a CAT"},
      {"icone": "🏛️", "texto": "O sindicato ou um familiar também podem emitir"},
      {"icone": "💰", "texto": "A CAT garante acesso aos benefícios do INSS"}
    ]
  },
  {
    "ordem": 9,
    "icone": "👥",
    "titulo": "SESMT e CIPA",
    "texto": "Duas estruturas essenciais para a segurança no trabalho:",
    "items": [
      {"icone": "🏥", "titulo": "SESMT", "texto": "Equipe interna com engenheiros, médicos e técnicos de segurança. Previne acidentes e protege a saúde dos trabalhadores.", "cor": "#EFF6FF"},
      {"icone": "🗳️", "titulo": "CIPA", "texto": "Comissão com representantes eleitos pelos trabalhadores. Identifica riscos e propõe melhorias. O cipeiro eleito tem estabilidade no emprego.", "cor": "#F0FDF4"}
    ]
  },
  {
    "ordem": 10,
    "icone": "🛑",
    "titulo": "Direito de Recusa e Emergências",
    "texto": "Você tem o DIREITO GARANTIDO POR LEI de se afastar quando houver risco grave e iminente. Exemplos:",
    "items": [
      {"icone": "🏗️", "texto": "Estrutura prestes a desabar"},
      {"icone": "💨", "texto": "Vazamento de gás ou produto químico perigoso"},
      {"icone": "⚙️", "texto": "Equipamento com defeito grave"},
      {"icone": "🦺", "texto": "Ausência de EPI em atividade de alto risco"}
    ],
    "destaque": "Em emergência: SAMU 192 · Bombeiros 193 · Defesa Civil 199"
  }
]'::jsonb
WHERE treinamento_id = (
  SELECT id FROM catalogo_treinamentos WHERE nr_relacionada = 'NR-01' LIMIT 1
);
