// SGS Plano Utils — helper compartilhado de limites de plano
// Incluir após trial_check.js nas páginas que precisam verificar limites

const SGS_PLANO_CACHE_KEY = 'sgs_plano_cache';

// Retorna o plano atual do usuário (com cache de sessão)
async function carregarPlanoAtual() {
  const cached = sessionStorage.getItem(SGS_PLANO_CACHE_KEY);
  if (cached) return JSON.parse(cached);

  const SUPA_URL = 'https://ookqdukeulwcnhilbgbo.supabase.co';
  const SUPA_KEY = 'sb_publishable_l9NggU-e1bgt7CnrYUWo4w_AMoaJa2e';
  const token    = localStorage.getItem('sgs_token');
  const userRaw  = localStorage.getItem('sgs_user');
  if (!token || !userRaw) return null;

  const user = JSON.parse(userRaw);

  try {
    const res = await fetch(
      `${SUPA_URL}/rest/v1/assinaturas?user_id=eq.${user.id}&ativo=eq.true` +
      `&select=status,planos(nome,limite_empresas,limite_funcionarios,numero_usuarios,tem_esocial,valor_mensal)` +
      `&order=criado_em.desc&limit=1`,
      { headers: { 'apikey': SUPA_KEY, 'Authorization': `Bearer ${token}` } }
    );
    if (!res.ok) return null;

    const data = await res.json();
    const assin = data[0];
    if (!assin) return null;

    // SUPERADMIN: sem limites
    const resPerfil = await fetch(
      `${SUPA_URL}/rest/v1/usuarios?user_id=eq.${user.id}&select=perfil`,
      { headers: { 'apikey': SUPA_KEY, 'Authorization': `Bearer ${token}` } }
    );
    const perfil = await resPerfil.json();
    const isSuperAdmin = perfil[0]?.perfil === 'SUPERADMIN';

    const plano = isSuperAdmin
      ? { nome: 'Enterprise', limite_empresas: 9999, limite_funcionarios: 99999, numero_usuarios: 9999, tem_esocial: true, valor_mensal: 0 }
      : (assin.planos || { nome: 'Free', limite_empresas: 2, limite_funcionarios: 25, numero_usuarios: 1, tem_esocial: false, valor_mensal: 0 });

    const resultado = {
      status: isSuperAdmin ? 'Enterprise' : assin.status,
      isPago: isSuperAdmin || assin.status === 'Ativo' || assin.status === 'Enterprise',
      isFree: !isSuperAdmin && assin.status === 'Free',
      plano
    };

    sessionStorage.setItem(SGS_PLANO_CACHE_KEY, JSON.stringify(resultado));
    return resultado;
  } catch(e) {
    console.error('Erro ao carregar plano:', e);
    return null;
  }
}

// Invalida o cache (chamar após upgrade de plano)
function invalidarCachePlano() {
  sessionStorage.removeItem(SGS_PLANO_CACHE_KEY);
}

// Conta empresas ativas do usuário
async function contarEmpresasAtivas() {
  const SUPA_URL = 'https://ookqdukeulwcnhilbgbo.supabase.co';
  const SUPA_KEY = 'sb_publishable_l9NggU-e1bgt7CnrYUWo4w_AMoaJa2e';
  const token    = localStorage.getItem('sgs_token');
  const userRaw  = localStorage.getItem('sgs_user');
  if (!token || !userRaw) return 0;

  const user = JSON.parse(userRaw);
  try {
    const res = await fetch(
      `${SUPA_URL}/rest/v1/empresas?user_id=eq.${user.id}&ativo=eq.true&select=id`,
      { headers: { 'apikey': SUPA_KEY, 'Authorization': `Bearer ${token}`, 'Prefer': 'count=exact', 'Range': '0-0' } }
    );
    return parseInt(res.headers.get('content-range')?.split('/')[1] || '0');
  } catch(e) { return 0; }
}

// Conta total de funcionários ativos em todas as empresas do usuário
async function contarFuncionariosAtivos() {
  const SUPA_URL = 'https://ookqdukeulwcnhilbgbo.supabase.co';
  const SUPA_KEY = 'sb_publishable_l9NggU-e1bgt7CnrYUWo4w_AMoaJa2e';
  const token    = localStorage.getItem('sgs_token');
  const userRaw  = localStorage.getItem('sgs_user');
  if (!token || !userRaw) return 0;

  const user = JSON.parse(userRaw);
  try {
    const res = await fetch(
      `${SUPA_URL}/rest/v1/empresas?user_id=eq.${user.id}&ativo=eq.true&select=total_funcionarios_cadastrados`,
      { headers: { 'apikey': SUPA_KEY, 'Authorization': `Bearer ${token}` } }
    );
    const data = await res.json();
    return data.reduce((acc, e) => acc + (e.total_funcionarios_cadastrados || 0), 0);
  } catch(e) { return 0; }
}

// Verifica limite antes de criar empresa. Retorna true se pode prosseguir.
async function verificarLimiteEmpresas() {
  const info = await carregarPlanoAtual();
  if (!info) return true; // sem dados, deixa passar (falha silenciosa)

  const total  = await contarEmpresasAtivas();
  const limite = info.plano.limite_empresas;

  if (total >= limite) {
    mostrarModalUpgrade('empresas', total, limite, info.plano.nome);
    return false;
  }
  return true;
}

// Verifica limite antes de criar funcionário. Retorna true se pode prosseguir.
async function verificarLimiteFuncionarios() {
  const info = await carregarPlanoAtual();
  if (!info) return true;

  const total  = await contarFuncionariosAtivos();
  const limite = info.plano.limite_funcionarios;

  if (total >= limite) {
    mostrarModalUpgrade('funcionarios', total, limite, info.plano.nome);
    return false;
  }
  return true;
}

// Modal de upgrade padronizado
function mostrarModalUpgrade(tipo, total, limite, planoAtual) {
  const tipoTexto  = tipo === 'empresas' ? 'empresas' : 'funcionários';
  const proximoPlano = _proximoPlano(planoAtual);

  const overlay = document.createElement('div');
  overlay.id = 'modal-upgrade';
  overlay.style.cssText = 'position:fixed;inset:0;background:rgba(15,17,23,.92);z-index:99999;display:flex;align-items:center;justify-content:center;font-family:"IBM Plex Sans",sans-serif;';
  overlay.innerHTML = `
    <div style="max-width:440px;width:90%;background:#181c27;border:1px solid #2a3044;border-radius:16px;padding:36px;text-align:center;">
      <div style="font-size:36px;margin-bottom:16px;">🚀</div>
      <div style="font-size:18px;font-weight:600;color:#e8eaf0;margin-bottom:10px;">
        Limite do plano ${planoAtual} atingido
      </div>
      <div style="font-size:13px;color:#8892a4;line-height:1.6;margin-bottom:8px;">
        Você já tem <strong style="color:#e8eaf0;">${total} ${tipoTexto}</strong> cadastrados.<br>
        O plano <strong style="color:#e8eaf0;">${planoAtual}</strong> permite até <strong style="color:#e8eaf0;">${limite} ${tipoTexto}</strong>.
      </div>
      ${proximoPlano ? `<div style="font-size:12px;color:#2dd4a0;margin-bottom:24px;">Faça upgrade para o plano <strong>${proximoPlano}</strong> e continue crescendo.</div>` : ''}
      <div style="display:flex;gap:10px;justify-content:center;flex-wrap:wrap;">
        <a href="assinar.html" style="display:inline-flex;align-items:center;gap:6px;background:#2dd4a0;color:#0f1117;font-size:14px;font-weight:600;padding:12px 24px;border-radius:6px;text-decoration:none;">
          ✨ Ver planos
        </a>
        <button onclick="document.getElementById('modal-upgrade').remove()"
          style="background:#1e2333;border:1px solid #2a3044;color:#8892a4;font-size:14px;padding:12px 24px;border-radius:6px;cursor:pointer;font-family:inherit;">
          Fechar
        </button>
      </div>
    </div>`;
  document.body.appendChild(overlay);
}

// Retorna o nome do próximo plano acima do atual
function _proximoPlano(planoAtual) {
  const escala = ['Free', 'Starter', 'Pro', 'Business', 'Enterprise'];
  const idx = escala.indexOf(planoAtual);
  return idx >= 0 && idx < escala.length - 1 ? escala[idx + 1] : null;
}

// Banner de eSocial bloqueado (plano Free)
function mostrarBannerEsocialBloqueado(containerId) {
  const el = document.getElementById(containerId);
  if (!el) return;
  el.innerHTML = `
    <div style="background:#1a2540;border:1px solid #2a4070;border-radius:10px;padding:20px;text-align:center;margin:16px 0;">
      <div style="font-size:24px;margin-bottom:8px;">🔒</div>
      <div style="font-size:14px;font-weight:500;color:#e8eaf0;margin-bottom:6px;">eSocial disponível nos planos pagos</div>
      <div style="font-size:12px;color:#8892a4;margin-bottom:16px;">Automatize a transmissão dos eventos S-2210, S-2220 e S-2240 a partir do plano Starter (R$ 79/mês).</div>
      <a href="assinar.html" style="display:inline-flex;align-items:center;gap:6px;background:#4a7cdc;color:#fff;font-size:13px;font-weight:600;padding:10px 20px;border-radius:6px;text-decoration:none;">
        Ver planos →
      </a>
    </div>`;
}
