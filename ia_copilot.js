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

const _GROQ_KEY='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';
const _GROQ_URL='https://api.groq.com/openai/v1/chat/completions';

async function _chamarGemini(prompt){
  const res=await fetch(_GROQ_URL,{
    method:'POST',
    headers:{'Content-Type':'application/json','Authorization':'Bearer '+_GROQ_KEY},
    body:JSON.stringify({
      model:'llama-3.1-8b-instant',
      messages:[{role:'user',content:prompt}],
      temperature:0.2,
      max_tokens:512
    })
  });
  if(!res.ok){
    const err=await res.json().catch(()=>({}));
    if(res.status===429)throw new Error('Limite de requisições atingido — aguarde alguns segundos e tente novamente.');
    if(res.status===401)throw new Error('Chave da IA inválida ou expirada — contate o suporte.');
    throw new Error(err.error?.message||'Erro HTTP '+res.status);
  }
  const data=await res.json();
  let text=data.choices?.[0]?.message?.content||'';
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
  const prompt=`Você é especialista em Saúde e Segurança do Trabalho (SST) no Brasil.
Analise a função "${nomeFuncao}" e responda SOMENTE com JSON válido, sem markdown:
{
  "descricao": "descrição das atividades principais da função em 2-3 frases objetivas",
  "trabalho_altura": false,
  "trabalho_confinado": false,
  "trabalho_eletrico": false,
  "insalubre": false,
  "periculoso": false
}
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
