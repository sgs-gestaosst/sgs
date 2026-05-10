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

const _GEMINI_KEY='AIzaSyCGxzEupDbRr3qE5-FDFPoeDERpsxVtCzk';
const _GEMINI_URL=`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent?key=${_GEMINI_KEY}`;

async function _chamarGemini(prompt){
  const res=await fetch(_GEMINI_URL,{
    method:'POST',
    headers:{'Content-Type':'application/json'},
    body:JSON.stringify({
      contents:[{parts:[{text:prompt}]}],
      generationConfig:{temperature:0.2,maxOutputTokens:512}
    })
  });
  if(!res.ok){const err=await res.json().catch(()=>({}));throw new Error(err.error?.message||'Erro HTTP '+res.status);}
  const data=await res.json();
  let text=data.candidates?.[0]?.content?.parts?.[0]?.text||'';
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
  return JSON.parse(text);
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
  return JSON.parse(text);
}

async function ia_sugerirMedida(nomeRisco,catRisco,tipoMedida){
  const descTipo={
    elim:'Eliminação — remover completamente a fonte do risco',
    subs:'Substituição — substituir por processo ou material menos perigoso',
    eng:'Engenharia — enclausuramento, exaustão local, barreiras físicas, isolamento',
    adm:'Administrativa — procedimentos, treinamentos, rodízio, sinalização, limitação de tempo de exposição',
    epi:'EPI — Equipamento de Proteção Individual adequado ao risco'
  }[tipoMedida]||tipoMedida;
  const prompt=`Você é especialista em Saúde e Segurança do Trabalho (SST) no Brasil.
Sugira uma medida de controle do tipo "${descTipo}" para o risco "${nomeRisco}" (categoria: ${catRisco}).
Requisitos: técnica, específica, baseada nas NRs brasileiras vigentes, aplicável na prática.
Responda SOMENTE com o texto da medida em 1-3 frases. Sem títulos, prefixos ou formatação.`;
  return await _chamarGemini(prompt);
}
