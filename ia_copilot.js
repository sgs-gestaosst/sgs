// ── IA COPILOT SST ────────────────────────────────────────────
// Integração com Google Gemini para sugestões em formulários SST

(function(){
  const style=document.createElement('style');
  style.textContent=`
    .btn-ia{display:inline-flex;align-items:center;gap:6px;padding:7px 14px;border-radius:6px;
      font-family:'IBM Plex Sans',sans-serif;font-size:12px;font-weight:500;cursor:pointer;
      border:1px solid #6366f1;background:#1e1a3a;color:#a5b4fc;transition:all .15s;}
    .btn-ia:hover{background:#2a2550;border-color:#818cf8;color:#c7d2fe;}
    .btn-ia:disabled{opacity:.5;cursor:not-allowed;}
    .ia-status{font-size:11px;margin-top:6px;}
    .btn-ia-medida{position:absolute;top:6px;right:6px;padding:3px 8px;border-radius:4px;
      font-size:11px;cursor:pointer;border:1px solid #6366f1;background:#1e1a3a;color:#a5b4fc;
      transition:all .15s;line-height:1.4;z-index:1;}
    .btn-ia-medida:hover{background:#2a2550;}
    .btn-ia-medida:disabled{opacity:.5;cursor:not-allowed;}
    .agentes-check-grid{display:flex;flex-wrap:wrap;gap:8px 20px;margin-top:6px;}
    .agentes-check-grid label{display:flex;align-items:center;gap:6px;font-size:12px;
      color:#8892a4;cursor:pointer;text-transform:none;letter-spacing:0;font-weight:400;}
    .agentes-check-grid input[type=checkbox]{accent-color:#4a7cdc;cursor:pointer;width:14px;height:14px;}
  `;
  document.head.appendChild(style);
})();

const _IA_PROXY_URL='https://ookqdukeulwcnhilbgbo.supabase.co/functions/v1/ia-proxy';
const _SUPA_ANON_KEY='sb_publishable_l9NggU-e1bgt7CnrYUWo4w_AMoaJa2e';

async function _chamarGemini(prompt){
  const token=localStorage.getItem('sgs_token');
  const res=await fetch(_IA_PROXY_URL,{
    method:'POST',
    headers:{
      'Content-Type':'application/json',
      'Authorization':'Bearer '+token,
      'apikey':_SUPA_ANON_KEY
    },
    body:JSON.stringify({prompt})
  });
  const data=await res.json().catch(()=>({}));
  if(!res.ok){
    if(res.status===429)throw new Error('Limite de requisições atingido — aguarde alguns segundos e tente novamente.');
    if(res.status===401)throw new Error('Sessão expirada — faça login novamente.');
    throw new Error(data.error||'Erro HTTP '+res.status);
  }
  let text=data.text||'';
  return text.replace(/```json\s*/g,'').replace(/```\s*/g,'').trim();
}

async function ia_sugerirSetor(nomeSetor){
  const prompt=`Você é especialista em Saúde e Segurança do Trabalho (SST) no Brasil.
Analise o setor "${nomeSetor}" de uma empresa e responda SOMENTE com JSON válido, sem markdown:
{
  "descricao": "descrição das atividades do setor em 2-3 frases objetivas",
  "tem_agente_fisico": false,
  "tem_agente_quimico": false,
  "tem_agente_biologico": false,
  "tem_agente_ergonomico": false,
  "tem_agente_acidente": false,
  "tem_agente_psicossocial": false
}
Critérios para true: fisico=ruído/vibração/calor/frio/radiação; quimico=poeiras/fumos/gases/solventes; biologico=vírus/bactérias/fungos; ergonomico=postura forçada/repetição/levantamento de peso; acidente=quedas/cortes/esmagamentos/choques elétricos; psicossocial=pressão por metas/jornada excessiva/assédio.`;
  const text=await _chamarGemini(prompt);
  try{
    const parsed=JSON.parse(text);
    if(typeof parsed.descricao!=='string')throw new Error('Campo descricao ausente');
    return parsed;
  }catch(e){throw new Error('IA retornou resposta inválida para setor. Tente novamente.');}
}

async function ia_sugerirFuncao(nomeFuncao){
  const prompt=`Você é especialista em Saúde e Segurança do Trabalho (SST) no Brasil, com experiência em elaboração de PGR, LTCAT e PCMSO.
Analise a função "${nomeFuncao}" e responda SOMENTE com JSON válido, sem markdown:
{
  "descricao": "...",
  "trabalho_altura": false,
  "trabalho_confinado": false,
  "trabalho_eletrico": false,
  "insalubre": false,
  "periculoso": false
}

Para o campo "descricao", escreva 3 a 4 frases técnicas incluindo obrigatoriamente:
1. Atividades e tarefas principais executadas no dia a dia
2. Ferramentas, equipamentos ou materiais utilizados habitualmente
3. Postura predominante (em pé, sentado, agachado, etc.) e nível de esforço físico envolvido
4. Ambiente de trabalho (interno/externo, local fechado/aberto, condições relevantes)
Use linguagem técnica compatível com laudos e documentos SST (PGR, LTCAT, PCMSO). Seja específico para a função — evite descrições genéricas.

Critérios para true: altura=trabalho habitual acima de 2m/NR-35; confinado=espaços confinados/NR-33; eletrico=instalações elétricas energizadas/NR-10; insalubre=exposição a agentes físicos/químicos/biológicos acima dos limites/NR-15; periculoso=inflamáveis/explosivos/alta tensão/radiações ionizantes/NR-16.`;
  const text=await _chamarGemini(prompt);
  try{
    const parsed=JSON.parse(text);
    if(typeof parsed.descricao!=='string')throw new Error('Campo descricao ausente');
    return parsed;
  }catch(e){throw new Error('IA retornou resposta inválida para função. Tente novamente.');}
}

async function ia_sugerirRiscos(nomeContexto,tipoContexto,catalogoRiscos,ctxRico={}){
  const lista=catalogoRiscos.map(r=>`${r.id}: ${r.nome_risco} (${r.categoria})`).join('\n');

  // Monta bloco de contexto com todas as informações disponíveis
  const linhasCtx=[];
  if(ctxRico.setorNome)linhasCtx.push(`Setor: ${ctxRico.setorNome}`);
  if(ctxRico.setorDescricao)linhasCtx.push(`Descrição do setor: ${ctxRico.setorDescricao}`);
  const agNomes=[
    ctxRico.agentes?.fisico&&'Físico (ruído, calor, vibração, radiação)',
    ctxRico.agentes?.quimico&&'Químico (poeiras, fumos, gases, solventes)',
    ctxRico.agentes?.biologico&&'Biológico (vírus, bactérias, fungos)',
    ctxRico.agentes?.ergonomico&&'Ergonômico (postura, repetição, esforço)',
    ctxRico.agentes?.acidente&&'Acidente (quedas, cortes, choques elétricos)',
    ctxRico.agentes?.psicossocial&&'Psicossocial (pressão, assédio, jornada)',
  ].filter(Boolean);
  if(agNomes.length)linhasCtx.push(`Agentes de risco presentes no setor: ${agNomes.join('; ')}`);
  if(tipoContexto==='função'){
    if(ctxRico.funcaoDescricao)linhasCtx.push(`Descrição da função: ${ctxRico.funcaoDescricao}`);
    const conds=[
      ctxRico.trabalhoAltura&&'trabalho em altura (NR-35)',
      ctxRico.trabalhoConfinado&&'espaços confinados (NR-33)',
      ctxRico.trabalhoEletrico&&'instalações elétricas (NR-10)',
      ctxRico.insalubre&&'atividade insalubre (NR-15)',
      ctxRico.periculoso&&'atividade perigosa (NR-16)',
    ].filter(Boolean);
    if(conds.length)linhasCtx.push(`Condições especiais da função: ${conds.join(', ')}`);
  }
  const blocoCtx=linhasCtx.length?`\nCONTEXTO:\n${linhasCtx.join('\n')}\n`:''

  const prompt=`Você é especialista em Saúde e Segurança do Trabalho (SST) no Brasil.
${blocoCtx}
Com base no contexto acima, selecione do catálogo os riscos ocupacionais mais prováveis para o ${tipoContexto} "${nomeContexto}". Priorize os agentes identificados no setor e considere as descrições fornecidas.

CATÁLOGO:
${lista}

Responda SOMENTE com JSON válido, sem markdown:
{"ids": [IDs inteiros dos riscos mais relevantes]}

Selecione entre 3 e 8 riscos. Use apenas IDs do catálogo acima.`;

  const text=await _chamarGemini(prompt);
  try{
    const parsed=JSON.parse(text);
    return Array.isArray(parsed.ids)?parsed.ids.map(Number):[];
  }catch(e){throw new Error('IA retornou resposta inválida. Tente novamente.');}
}

async function ia_sugerirEPI(nomeRisco,catRisco,epiIndicado,viaAbsorcao,catalogoEpis,fonteGeradora,danosSaude){
  const lista=catalogoEpis.map(e=>`${e.id}: ${e.nome} (${e.categoria})`).join('\n');
  const linhasCtx=[
    `Risco: ${nomeRisco}`,
    `Categoria: ${catRisco}`,
    viaAbsorcao?`Via de absorção: ${viaAbsorcao}`:'',
    fonteGeradora?`Fonte geradora: ${fonteGeradora}`:'',
    danosSaude?`Danos à saúde: ${danosSaude}`:'',
    epiIndicado?`EPIs recomendados pelo catálogo de riscos: "${epiIndicado}"`:''
  ].filter(Boolean).join('\n');
  const prompt=`Você é especialista em Saúde e Segurança do Trabalho (SST) no Brasil.

CONTEXTO DO RISCO:
${linhasCtx}

Com base no contexto acima, selecione do catálogo abaixo apenas os EPIs que tenham relação direta com a proteção contra este risco. Use a via de absorção, fonte geradora e danos à saúde para identificar quais partes do corpo precisam de proteção.

ATENÇÃO: Se nenhum EPI do catálogo for adequado (ex: riscos ergonômicos geralmente não têm EPI específico), responda com ids vazio. Não force sugestões inadequadas.

CATÁLOGO DE EPIs DISPONÍVEIS:
${lista}

Responda SOMENTE com JSON válido, sem markdown:
{"ids": [IDs dos EPIs diretamente adequados, ou array vazio se nenhum for pertinente]}

Selecione no máximo 4 EPIs. Use apenas IDs existentes no catálogo acima.`;
  const text=await _chamarGemini(prompt);
  try{
    const parsed=JSON.parse(text);
    return Array.isArray(parsed.ids)?parsed.ids.map(Number):[];
  }catch(e){throw new Error('IA retornou resposta inválida. Tente novamente.');}
}

async function ia_sugerirConclusao(nomeRisco,catRisco,fonteGeradora,viaAbsorcao,danosSaude,metodologia,probabilidade,severidade){
  const nivel={1:'Muito baixa',2:'Baixa',3:'Média',4:'Alta',5:'Muito alta'};
  const nivelS={1:'Insignificante',2:'Leve',3:'Moderada',4:'Grave',5:'Catastrófica'};
  const ps=(probabilidade&&severidade)?probabilidade*severidade:null;
  const nivelRisco=ps?ps>=15?'Muito Alto':ps>=8?'Alto':ps>=4?'Médio':'Baixo':'não definido';
  const prompt=`Você é especialista em Saúde e Segurança do Trabalho (SST) no Brasil.
Elabore uma conclusão técnica objetiva para a avaliação qualitativa do seguinte risco ocupacional:

Risco: ${nomeRisco}
Categoria: ${catRisco}
${fonteGeradora?`Fonte geradora: ${fonteGeradora}`:''}
${viaAbsorcao?`Via de absorção: ${viaAbsorcao}`:''}
${danosSaude?`Danos à saúde: ${danosSaude}`:''}
${metodologia?`Metodologia aplicada: ${metodologia}`:''}
${probabilidade?`Probabilidade: ${probabilidade} — ${nivel[probabilidade]||''}`:''} ${severidade?`| Severidade: ${severidade} — ${nivelS[severidade]||''}`:''} ${ps?`| Nível: ${nivelRisco}`:''}

Escreva 2 a 3 frases técnicas descrevendo: a condição de exposição identificada, o nível de risco encontrado e a justificativa. Baseie-se nas NRs brasileiras vigentes. Sem títulos, sem bullets, texto corrido.`;
  return await _chamarGemini(prompt);
}

async function ia_sugerirAtividadesAET(nomeFuncao,nomeSetor){
  const prompt=`Você é especialista em Saúde e Segurança do Trabalho (SST) no Brasil, com experiência em elaboração de AET (Análise Ergonômica do Trabalho) conforme NR-17.
Elabore a descrição das atividades para a função "${nomeFuncao}" no setor "${nomeSetor}".
Escreva 4 a 6 frases técnicas, em texto corrido, cobrindo obrigatoriamente:
1. Principais tarefas executadas no ciclo de trabalho
2. Ferramentas, equipamentos ou materiais manuseados
3. Postura predominante (em pé, sentado, agachado, etc.) e movimentos mais frequentes (flexão, rotação, extensão)
4. Esforço físico envolvido (levantamento de cargas, aplicação de força, movimentos repetitivos)
5. Interações com outros trabalhadores ou sistemas
Use linguagem técnica adequada a laudos e documentos SST. Sem títulos, sem tópicos, texto corrido. Responda SOMENTE com o texto, sem aspas nem markdown.`;
  return await _chamarGemini(prompt);
}

async function ia_sugerirPostoAET(nomeFuncao,nomeSetor){
  const prompt=`Você é especialista em Saúde e Segurança do Trabalho (SST) no Brasil, com experiência em elaboração de AET (Análise Ergonômica do Trabalho) conforme NR-17.
Elabore a descrição do posto de trabalho para a função "${nomeFuncao}" no setor "${nomeSetor}".
Escreva 3 a 5 frases técnicas, em texto corrido, cobrindo obrigatoriamente:
1. Características do ambiente físico (interno/externo, área, layout)
2. Mobiliário e equipamentos presentes (bancadas, cadeiras, telas, máquinas)
3. Condições ambientais relevantes (iluminação, temperatura, ruído, vibração, ventilação)
4. Dimensões e organização do espaço em relação às tarefas executadas
Use linguagem técnica adequada a laudos SST. Sem títulos, sem tópicos, texto corrido. Responda SOMENTE com o texto, sem aspas nem markdown.`;
  return await _chamarGemini(prompt);
}

async function ia_sugerirConclusaoMet(nomeFuncao,nomeSetor,metodologia,nivelRisco,score,exposicao){
  const prompt=`Você é especialista em Saúde e Segurança do Trabalho (SST) no Brasil, com experiência em ergonomia e elaboração de AET conforme NR-17.
Elabore a conclusão técnica de uma avaliação ergonômica com os seguintes dados:
- Função: ${nomeFuncao}
- Setor: ${nomeSetor}
- Metodologia aplicada: ${metodologia}
- Escore obtido: ${score}
- Nível de risco: ${nivelRisco}
- Exposição habitual e permanente: ${exposicao?'Sim':'Não'}

Escreva 3 a 5 frases técnicas em texto corrido, incluindo obrigatoriamente:
1. Síntese do resultado da avaliação (escore e nível de risco identificado)
2. Principais fatores ergonômicos identificados para esta função/metodologia
3. Indicação de ação conforme o nível (ex: se nível 1-2: monitorar; se 3-4: investigar e implementar mudanças; se 5-6: mudanças urgentes; se 7+: parar e redesenhar)
4. Referência à NR-17 ou normativa aplicável
Use linguagem técnica compatível com laudos SST. Sem títulos, sem tópicos, texto corrido. Responda SOMENTE com o texto, sem aspas nem markdown.`;
  return await _chamarGemini(prompt);
}

async function ia_sugerirTarefaAET(nomeFuncao,nomeSetor,metodologia){
  const prompt=`Você é especialista em ergonomia e Saúde e Segurança do Trabalho (SST) no Brasil.
Elabore a descrição da tarefa/ciclo de trabalho para aplicação da metodologia ${metodologia} na função "${nomeFuncao}" no setor "${nomeSetor}".
Escreva 2 a 3 frases técnicas em texto corrido, descrevendo: o ciclo de trabalho principal avaliado, os movimentos e posturas envolvidos, e a frequência/cadência da tarefa.
Use linguagem compatível com laudos ergonômicos. Sem títulos, sem tópicos. Responda SOMENTE com o texto, sem aspas nem markdown.`;
  return await _chamarGemini(prompt);
}

async function ia_sugerirPausasAET(nomeFuncao,nomeSetor){
  const prompt=`Você é especialista em Saúde e Segurança do Trabalho (SST) no Brasil, com experiência em NR-17 (Ergonomia).
Sugira as pausas e períodos de descanso recomendados para a função "${nomeFuncao}" no setor "${nomeSetor}", de acordo com a NR-17 e boas práticas ergonômicas.
Inclua: frequência e duração das pausas, fundamentação na NR-17 (subitem relevante quando aplicável), e recomendações de ginástica laboral se pertinente.
Escreva 2 a 4 frases técnicas em texto corrido. Sem títulos, sem tópicos. Responda SOMENTE com o texto, sem aspas nem markdown.`;
  return await _chamarGemini(prompt);
}

async function ia_sugerirMetasAET(nomeFuncao,nomeSetor){
  const prompt=`Você é especialista em Saúde e Segurança do Trabalho (SST) no Brasil, com experiência em NR-17 (Ergonomia).
Descreva tecnicamente como as metas de produção e o ritmo de trabalho impactam a função "${nomeFuncao}" no setor "${nomeSetor}", sob a perspectiva ergonômica e da NR-17.
Aborde: se há metas formais ou informais, o ritmo imposto pelo processo ou máquina, e o impacto sobre a carga física e mental do trabalhador.
Escreva 2 a 3 frases técnicas em texto corrido. Sem títulos, sem tópicos. Responda SOMENTE com o texto, sem aspas nem markdown.`;
  return await _chamarGemini(prompt);
}

async function ia_sugerirMedida(nomeRisco,catRisco,tipoMedida,conclusaoTecnica=''){
  const descTipo={
    elim:'Eliminação — remover completamente a fonte do risco',
    subs:'Substituição — substituir por processo ou material menos perigoso',
    eng:'Engenharia — enclausuramento, exaustão local, barreiras físicas, isolamento',
    adm:'Administrativa — procedimentos, treinamentos, rodízio, sinalização, limitação de tempo de exposição',
    epi:'EPI — Equipamento de Proteção Individual adequado ao risco'
  }[tipoMedida]||tipoMedida;
  const ctxAvaliacao=conclusaoTecnica?`\nContexto da avaliação realizada:\n"${conclusaoTecnica}"\n`:'';
  const prompt=`Você é especialista em Saúde e Segurança do Trabalho (SST) no Brasil.
Sugira uma medida de controle do tipo "${descTipo}" para o risco "${nomeRisco}" (categoria: ${catRisco}).${ctxAvaliacao}
Requisitos: técnica, específica, baseada nas NRs brasileiras vigentes, aplicável na prática. Use o contexto da avaliação para tornar a sugestão mais precisa.
Responda SOMENTE com o texto da medida em 1-3 frases. Sem títulos, prefixos ou formatação.`;
  return await _chamarGemini(prompt);
}
